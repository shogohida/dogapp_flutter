import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/dog.dart';
import '../models/walk.dart';
import '../theme/app_theme.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// dogapp-api (Go実装)との通信を担う層。
/// 画面側はこのインターフェースだけを見るので、テストではフェイク実装に
/// 差し替えられる(test/fakes/fake_dogapp_api_client.dart参照)。
abstract class DogappApiClient {
  Future<List<Dog>> fetchDogs(String ownerId);

  Future<AICheckResult> runAiCheck({
    required String dogId,
    required Uint8List imageBytes,
  });

  /// 短い動画から歩き方の異常(引きずり・跛行など)を簡易チェックする。
  Future<AICheckResult> runGaitCheck({
    required String dogId,
    required Uint8List videoBytes,
    required String filename,
  });

  Future<HealthRecord> createRecord({
    required String dogId,
    required RecordType type,
    required String label,
  });

  Future<List<WalkRoute>> fetchWalks(String dogId);

  Future<WalkRoute> createWalk({
    required String dogId,
    required DateTime startedAt,
    required Duration duration,
    required double distanceMeters,
    required List<GeoPoint> points,
  });
}

/// 実際にdogapp-apiへHTTPリクエストを送る実装。
///
/// 注: フィールド名(id/name/birthYearなど)とtype/levelの文字列表現
/// (RecordType.name / AICheckLevel.name = 'vaccine', 'watch' など)は、
/// dogapp-apiの実際のJSONレスポンスに合わせて調整が必要な想定値。
/// 変更が必要な場合はこのファイルと lib/models/dog.dart の
/// fromJson/toJson だけを直せばよいよう分離している。
class HttpDogappApiClient implements DogappApiClient {
  HttpDogappApiClient(
      {http.Client? httpClient, String? baseUrl, Duration? timeout})
      : _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _timeout = timeout ?? const Duration(seconds: 10);

  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  @override
  Future<List<Dog>> fetchDogs(String ownerId) async {
    final uri = Uri.parse('$_baseUrl/owners/$ownerId/dogs');
    final res = await _client.get(uri).timeout(_timeout);
    _checkStatus(res);
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return [
      for (var i = 0; i < list.length; i++)
        Dog.fromJson(
          list[i] as Map<String, dynamic>,
          accent: AppColors.accentPalette[i % AppColors.accentPalette.length],
        ),
    ];
  }

  @override
  Future<AICheckResult> runAiCheck({
    required String dogId,
    required Uint8List imageBytes,
  }) async {
    final uri = Uri.parse('$_baseUrl/dogs/$dogId/ai-check');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'imageBase64': base64Encode(imageBytes)}),
        )
        // 画像解析はClaude API呼び出しを挟むぶん時間がかかりうるため、
        // 他のエンドポイントより長めのタイムアウトにする。
        .timeout(_timeout * 3);
    _checkStatus(res);
    return AICheckResult.fromJson(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }

  @override
  Future<AICheckResult> runGaitCheck({
    required String dogId,
    required Uint8List videoBytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$_baseUrl/dogs/$dogId/gait-check');
    // 動画はBase64+JSONだとリクエストが肥大化しやすいため、写真とは違い
    // multipart/form-dataでアップロードする。
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('video', videoBytes,
          filename: filename));
    final streamedResponse = await _client.send(request).timeout(_timeout * 3);
    final res = await http.Response.fromStream(streamedResponse);
    _checkStatus(res);
    return AICheckResult.fromJson(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }

  @override
  Future<HealthRecord> createRecord({
    required String dogId,
    required RecordType type,
    required String label,
  }) async {
    final uri = Uri.parse('$_baseUrl/dogs/$dogId/records');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'type': type.name, 'label': label}),
        )
        .timeout(_timeout);
    _checkStatus(res);
    return HealthRecord.fromJson(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<WalkRoute>> fetchWalks(String dogId) async {
    final uri = Uri.parse('$_baseUrl/dogs/$dogId/walks');
    final res = await _client.get(uri).timeout(_timeout);
    _checkStatus(res);
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return list
        .map((e) => WalkRoute.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WalkRoute> createWalk({
    required String dogId,
    required DateTime startedAt,
    required Duration duration,
    required double distanceMeters,
    required List<GeoPoint> points,
  }) async {
    final uri = Uri.parse('$_baseUrl/dogs/$dogId/walks');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'startedAt': startedAt.toIso8601String(),
            'durationSeconds': duration.inSeconds,
            'distanceMeters': distanceMeters,
            'points': points.map((p) => p.toJson()).toList(),
          }),
        )
        .timeout(_timeout);
    _checkStatus(res);
    return WalkRoute.fromJson(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('dogapp-api error (${res.statusCode}): ${res.body}');
    }
  }
}
