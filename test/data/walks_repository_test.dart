import 'dart:typed_data';

import 'package:dogapp/data/walks_repository.dart';
import 'package:dogapp/models/dog.dart';
import 'package:dogapp/models/user.dart';
import 'package:dogapp/models/walk.dart';
import 'package:dogapp/services/dogapp_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<AICheckResult> runAiCheck(
          {required String dogId, required Uint8List imageBytes}) =>
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
}
