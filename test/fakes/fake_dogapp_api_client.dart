import 'dart:typed_data';

import 'package:dogapp/data/mock_data.dart';
import 'package:dogapp/models/dog.dart';
import 'package:dogapp/models/walk.dart';
import 'package:dogapp/services/dogapp_api_client.dart';

/// 実ネットワークに依存せずウィジェットテストを走らせるためのフェイク実装。
/// 既存のモックデータ(mock_data.dart)をそのまま「サーバーからの応答」として返す。
class FakeDogappApiClient implements DogappApiClient {
  @override
  Future<List<Dog>> fetchDogs(String ownerId) async => mockDogs;

  @override
  Future<AICheckResult> runAiCheck({
    required String dogId,
    required Uint8List imageBytes,
  }) async {
    // 実ネットワークと同じくタイマー経由の遅延を挟むことで、呼び出し側の
    // 「analyzing」中間状態がテストのpump()で正しく観測できるようにする。
    await Future.delayed(const Duration(milliseconds: 50));
    return mockAIResults.first;
  }

  @override
  Future<AICheckResult> runGaitCheck({
    required String dogId,
    required Uint8List videoBytes,
    required String filename,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return mockAIResults.first;
  }

  @override
  Future<HealthRecord> createRecord({
    required String dogId,
    required RecordType type,
    required String label,
  }) async {
    return HealthRecord(id: 'fake-id', type: type, label: label, date: DateTime.now());
  }

  @override
  Future<List<WalkRoute>> fetchWalks(String dogId) async => [];

  @override
  Future<WalkRoute> createWalk({
    required String dogId,
    required DateTime startedAt,
    required Duration duration,
    required double distanceMeters,
    required List<GeoPoint> points,
  }) async {
    return WalkRoute(
      id: 'fake-walk-id',
      dogId: dogId,
      startedAt: startedAt,
      duration: duration,
      distanceMeters: distanceMeters,
      points: points,
    );
  }
}
