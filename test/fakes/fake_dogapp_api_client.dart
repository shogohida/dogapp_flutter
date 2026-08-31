import 'dart:typed_data';

import 'package:dogapp/data/mock_data.dart';
import 'package:dogapp/models/dog.dart';
import 'package:dogapp/models/user.dart';
import 'package:dogapp/models/walk.dart';
import 'package:dogapp/services/dogapp_api_client.dart';

/// 実ネットワークに依存せずウィジェットテストを走らせるためのフェイク実装。
/// 既存のモックデータ(mock_data.dart)をそのまま「サーバーからの応答」として返す。
class FakeDogappApiClient implements DogappApiClient {
  @override
  Future<AuthResult> signup(
          {required String email, required String password}) async =>
      AuthResult(
          token: 'fake-token', user: AppUser(id: 'fake-user', email: email));

  @override
  Future<AuthResult> login(
          {required String email, required String password}) async =>
      AuthResult(
          token: 'fake-token', user: AppUser(id: 'fake-user', email: email));

  // 呼び出し側がリストの要素を入れ替える(DogsRepository.addRecord/updateDogなど)
  // ことがあるため、共有のmockDogsそのものではなくコピーを返す。これを怠ると
  // あるテストでの更新が同じプロセス内の後続テストに漏れてしまう。
  @override
  Future<List<Dog>> fetchDogs() async => List.of(mockDogs);

  @override
  Future<Dog> createDog({
    required String name,
    required String breed,
    required String color,
    required int birthYear,
  }) async {
    return Dog(
      id: 'fake-dog-id',
      name: name,
      breed: breed,
      color: color,
      birthYear: birthYear,
      accent: mockDogs.first.accent,
      weightHistory: const [],
      records: const [],
    );
  }

  @override
  Future<void> updateDog({
    required String dogId,
    required String name,
    required String breed,
    required String color,
    required int birthYear,
  }) async {}

  @override
  Future<WeightEntry> addWeightEntry({
    required String dogId,
    required String month,
    required double kg,
  }) async {
    return WeightEntry(month: month, kg: kg);
  }

  @override
  Future<AICheckResult> runAiCheck({
    required String dogId,
    required Uint8List imageBytes,
    required String bodyPart,
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
    required String type,
    required String label,
    double? cost,
  }) async {
    return HealthRecord(
      id: 'fake-id',
      type: type,
      label: label,
      date: DateTime.now(),
      cost: cost,
    );
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

  @override
  Future<List<UpcomingItem>> fetchUpcoming() async => List.of(mockUpcoming);

  @override
  Future<UpcomingItem> createUpcoming({
    required String dogId,
    required RecordType type,
    required String label,
    required DateTime date,
  }) async {
    return UpcomingItem(
      id: 'fake-upcoming-id',
      dogId: dogId,
      label: label,
      date: date,
      type: type,
    );
  }
}
