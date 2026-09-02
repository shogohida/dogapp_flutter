import 'dart:async';
import 'dart:typed_data';

import 'package:dogapp/data/walks_repository.dart';
import 'package:dogapp/models/dog.dart';
import 'package:dogapp/models/user.dart';
import 'package:dogapp/models/walk.dart';
import 'package:dogapp/services/dogapp_api_client.dart';
import 'package:dogapp/services/location_service.dart';
import 'package:dogapp/utils/geo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

/// このテストではrecommendedCourses()の集計ロジックだけを確認するため、
/// GPS記録やHTTP呼び出しに関わるメソッドは使わない(呼ばれたら失敗させる)。
class _UnusedApiClient implements DogappApiClient {
  @override
  Future<AuthResult> signup(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AuthResult> login(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<List<Dog>> fetchDogs() => throw UnimplementedError();

  @override
  Future<Dog> createDog({
    required String name,
    required String breed,
    required String color,
    required int birthYear,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateDog({
    required String dogId,
    required String name,
    required String breed,
    required String color,
    required int birthYear,
  }) =>
      throw UnimplementedError();

  @override
  Future<WeightEntry> addWeightEntry({
    required String dogId,
    required String month,
    required double kg,
  }) =>
      throw UnimplementedError();

  @override
  Future<AICheckResult> runAiCheck({
    required String dogId,
    required Uint8List imageBytes,
    required String bodyPart,
  }) =>
      throw UnimplementedError();

  @override
  Future<AICheckResult> runGaitCheck({
    required String dogId,
    required Uint8List videoBytes,
    required String filename,
  }) =>
      throw UnimplementedError();

  @override
  Future<HealthRecord> createRecord({
    required String dogId,
    required String type,
    required String label,
    double? cost,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<WalkRoute>> fetchWalks(String dogId) =>
      throw UnimplementedError();

  @override
  Future<WalkRoute> createWalk({
    required String dogId,
    required DateTime startedAt,
    required Duration duration,
    required double distanceMeters,
    required List<GeoPoint> points,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<UpcomingItem>> fetchUpcoming() => throw UnimplementedError();

  @override
  Future<UpcomingItem> createUpcoming({
    required String dogId,
    required RecordType type,
    required String label,
    required DateTime date,
  }) =>
      throw UnimplementedError();
}

/// startRecording/stopRecording/discardRecordingの記録ライフサイクルを
/// 検証するためのフェイク。ensurePermission()の失敗と、positionStream()から
/// 任意のタイミングでGPS位置情報を流すことをテスト側から制御できる。
class _FakeLocationService extends LocationService {
  Object? permissionError;
  int ensurePermissionCallCount = 0;
  final _controller = StreamController<Position>.broadcast();

  void emit(Position position) => _controller.add(position);

  @override
  Future<void> ensurePermission() async {
    ensurePermissionCallCount++;
    if (permissionError != null) throw permissionError!;
  }

  @override
  Stream<Position> positionStream() => _controller.stream;

  void dispose() => _controller.close();
}

Position _position({required double lat, required double lng}) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 8, 31),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

/// createWalk()に渡された引数を記録しつつ、それをそのままWalkRouteとして
/// 返すフェイク。他のメソッドはこのテストで使わないため未実装のまま。
class _RecordingApiClient implements DogappApiClient {
  int createWalkCallCount = 0;
  List<GeoPoint>? lastPoints;
  double? lastDistanceMeters;

  @override
  Future<WalkRoute> createWalk({
    required String dogId,
    required DateTime startedAt,
    required Duration duration,
    required double distanceMeters,
    required List<GeoPoint> points,
  }) async {
    createWalkCallCount++;
    lastPoints = points;
    lastDistanceMeters = distanceMeters;
    return WalkRoute(
      id: 'saved-walk',
      dogId: dogId,
      startedAt: startedAt,
      duration: duration,
      distanceMeters: distanceMeters,
      points: points,
    );
  }

  @override
  Future<AuthResult> signup(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AuthResult> login(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<List<Dog>> fetchDogs() => throw UnimplementedError();

  @override
  Future<Dog> createDog({
    required String name,
    required String breed,
    required String color,
    required int birthYear,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateDog({
    required String dogId,
    required String name,
    required String breed,
    required String color,
    required int birthYear,
  }) =>
      throw UnimplementedError();

  @override
  Future<WeightEntry> addWeightEntry({
    required String dogId,
    required String month,
    required double kg,
  }) =>
      throw UnimplementedError();

  @override
  Future<AICheckResult> runAiCheck({
    required String dogId,
    required Uint8List imageBytes,
    required String bodyPart,
  }) =>
      throw UnimplementedError();

  @override
  Future<AICheckResult> runGaitCheck({
    required String dogId,
    required Uint8List videoBytes,
    required String filename,
  }) =>
      throw UnimplementedError();

  @override
  Future<HealthRecord> createRecord({
    required String dogId,
    required String type,
    required String label,
    double? cost,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<WalkRoute>> fetchWalks(String dogId) =>
      throw UnimplementedError();

  @override
  Future<List<UpcomingItem>> fetchUpcoming() => throw UnimplementedError();

  @override
  Future<UpcomingItem> createUpcoming({
    required String dogId,
    required RecordType type,
    required String label,
    required DateTime date,
  }) =>
      throw UnimplementedError();
}

WalkRoute _walk(
    {required double lat,
    required double lng,
    required double distanceMeters,
    int daysAgo = 0}) {
  return WalkRoute(
    id: '$lat,$lng,$daysAgo',
    dogId: 'leo',
    startedAt: DateTime(2026, 8, 27).subtract(Duration(days: daysAgo)),
    duration: const Duration(minutes: 20),
    distanceMeters: distanceMeters,
    points: [GeoPoint(lat: lat, lng: lng, timestamp: DateTime(2026, 8, 27))],
  );
}

void main() {
  test('開始地点が近い散歩をまとめ、回数の多い順に返す', () {
    final repo = WalksRepository(client: _UnusedApiClient());
    // 公園ルート: 同じ開始地点付近から3回
    repo.walks = [
      _walk(lat: 35.6580, lng: 139.7016, distanceMeters: 1200, daysAgo: 1),
      _walk(lat: 35.6581, lng: 139.7015, distanceMeters: 1300, daysAgo: 3),
      _walk(lat: 35.6580, lng: 139.7017, distanceMeters: 1000, daysAgo: 5),
      // 川沿いルート: 別の開始地点から1回だけ
      _walk(lat: 35.7000, lng: 139.7500, distanceMeters: 2500, daysAgo: 2),
    ];

    final courses = repo.recommendedCourses();

    expect(courses, hasLength(2));
    expect(courses.first.walkCount, 3);
    expect(courses.first.averageDistanceMeters, closeTo(1166.67, 1));
    expect(courses.last.walkCount, 1);
  });

  test('散歩記録が無ければ空リストを返す', () {
    final repo = WalksRepository(client: _UnusedApiClient());
    expect(repo.recommendedCourses(), isEmpty);
  });

  test('limitで返す件数を絞れる', () {
    final repo = WalksRepository(client: _UnusedApiClient());
    repo.walks = [
      _walk(lat: 1, lng: 1, distanceMeters: 100),
      _walk(lat: 2, lng: 2, distanceMeters: 100),
      _walk(lat: 3, lng: 3, distanceMeters: 100),
    ];

    expect(repo.recommendedCourses(limit: 2), hasLength(2));
  });

  group('GPS記録のライフサイクル', () {
    test('startRecordingは位置情報の許可を確認し、記録中フラグを立てる', () async {
      final location = _FakeLocationService();
      final repo =
          WalksRepository(client: _RecordingApiClient(), locationService: location);

      await repo.startRecording();

      expect(repo.isRecording, isTrue);
      expect(location.ensurePermissionCallCount, 1);
      expect(repo.currentPoints, isEmpty);
      expect(repo.currentDistanceMeters, 0);
      location.dispose();
    });

    test('位置情報の許可が得られない場合はrecordingErrorを設定し記録を開始しない', () async {
      final location = _FakeLocationService()
        ..permissionError =
            LocationServiceException(LocationFailure.permissionDenied);
      final repo =
          WalksRepository(client: _RecordingApiClient(), locationService: location);

      await repo.startRecording();

      expect(repo.isRecording, isFalse);
      expect(repo.recordingError, isA<LocationServiceException>());
      location.dispose();
    });

    test('GPS位置を受信するたびに現在地点と距離(haversine)が更新される', () async {
      final location = _FakeLocationService();
      final repo =
          WalksRepository(client: _RecordingApiClient(), locationService: location);
      await repo.startRecording();

      location.emit(_position(lat: 35.681, lng: 139.767));
      await Future.delayed(Duration.zero);
      location.emit(_position(lat: 35.682, lng: 139.768));
      await Future.delayed(Duration.zero);

      final expectedDistance =
          haversineMeters(35.681, 139.767, 35.682, 139.768);
      expect(repo.currentPoints, hasLength(2));
      expect(repo.currentDistanceMeters, closeTo(expectedDistance, 0.01));
      location.dispose();
    });

    test('stopRecordingはGPS点が2点未満なら保存せずnullを返す', () async {
      final location = _FakeLocationService();
      final client = _RecordingApiClient();
      final repo = WalksRepository(client: client, locationService: location);
      await repo.startRecording();
      location.emit(_position(lat: 35.681, lng: 139.767));
      await Future.delayed(Duration.zero);

      final result = await repo.stopRecording('leo');

      expect(result, isNull);
      expect(client.createWalkCallCount, 0);
      expect(repo.isRecording, isFalse);
      expect(repo.currentPoints, isEmpty);
      location.dispose();
    });

    test('stopRecordingは2点以上あれば保存し、履歴の先頭に追加する', () async {
      final location = _FakeLocationService();
      final client = _RecordingApiClient();
      final repo = WalksRepository(client: client, locationService: location);
      repo.walks = [_walk(lat: 0, lng: 0, distanceMeters: 500)];
      await repo.startRecording();
      location.emit(_position(lat: 35.681, lng: 139.767));
      await Future.delayed(Duration.zero);
      location.emit(_position(lat: 35.682, lng: 139.768));
      await Future.delayed(Duration.zero);

      final result = await repo.stopRecording('leo');

      expect(result, isNotNull);
      expect(client.createWalkCallCount, 1);
      expect(client.lastPoints, hasLength(2));
      expect(repo.walks, hasLength(2));
      expect(repo.walks.first, same(result));
      expect(repo.isRecording, isFalse);
      expect(repo.currentPoints, isEmpty);
      expect(repo.currentDistanceMeters, 0);
      location.dispose();
    });

    test('discardRecordingは保存せずに記録をリセットする', () async {
      final location = _FakeLocationService();
      final client = _RecordingApiClient();
      final repo = WalksRepository(client: client, locationService: location);
      await repo.startRecording();
      location.emit(_position(lat: 35.681, lng: 139.767));
      location.emit(_position(lat: 35.682, lng: 139.768));
      await Future.delayed(Duration.zero);

      repo.discardRecording();

      expect(client.createWalkCallCount, 0);
      expect(repo.isRecording, isFalse);
      expect(repo.currentPoints, isEmpty);
      expect(repo.currentDistanceMeters, 0);
      location.dispose();
    });
  });
}
