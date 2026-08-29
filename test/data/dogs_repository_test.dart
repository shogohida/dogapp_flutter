import 'dart:typed_data';

import 'package:dogapp/data/dogs_repository.dart';
import 'package:dogapp/models/dog.dart';
import 'package:dogapp/models/user.dart';
import 'package:dogapp/models/walk.dart';
import 'package:dogapp/services/dogapp_api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _leo = Dog(
  id: 'leo',
  name: 'レオ',
  breed: 'スタンダードプードル',
  color: 'アプリコット',
  birthYear: 2021,
  accent: Color(0xFFE2A63B),
  weightHistory: [],
  records: [],
);

class _StubApiClient implements DogappApiClient {
  _StubApiClient({
    this.dogsResult,
    this.dogsError,
    this.createRecordResult,
    this.upcomingResult,
    this.upcomingError,
    this.createUpcomingResult,
    this.createDogResult,
  });

  final List<Dog>? dogsResult;
  final Object? dogsError;
  final HealthRecord? createRecordResult;
  final List<UpcomingItem>? upcomingResult;
  final Object? upcomingError;
  final UpcomingItem? createUpcomingResult;
  final Dog? createDogResult;

  @override
  Future<AuthResult> signup(
          {required String email, required String password}) async =>
      AuthResult(token: 't', user: AppUser(id: 'u', email: email));

  @override
  Future<AuthResult> login(
          {required String email, required String password}) async =>
      AuthResult(token: 't', user: AppUser(id: 'u', email: email));

  @override
  Future<List<Dog>> fetchDogs() async {
    if (dogsError != null) throw dogsError!;
    return dogsResult!;
  }

  @override
  Future<Dog> createDog({
    required String name,
    required String breed,
    required String color,
    required int birthYear,
  }) async {
    return createDogResult!;
  }

  @override
  Future<List<UpcomingItem>> fetchUpcoming() async {
    if (upcomingError != null) throw upcomingError!;
    return upcomingResult ?? [];
  }

  @override
  Future<UpcomingItem> createUpcoming({
    required String dogId,
    required RecordType type,
    required String label,
    required DateTime date,
  }) async {
    return createUpcomingResult!;
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
  Future<AICheckResult> runAiCheck(
      {required String dogId, required Uint8List imageBytes}) async {
    return const AICheckResult(
        level: AICheckLevel.normal, title: 't', detail: 'd');
  }

  @override
  Future<AICheckResult> runGaitCheck({
    required String dogId,
    required Uint8List videoBytes,
    required String filename,
  }) async {
    return const AICheckResult(
        level: AICheckLevel.normal, title: 't', detail: 'd');
  }

  @override
  Future<HealthRecord> createRecord({
    required String dogId,
    required String type,
    required String label,
    double? cost,
  }) async {
    return createRecordResult!;
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
      id: 'stub-walk',
      dogId: dogId,
      startedAt: startedAt,
      duration: duration,
      distanceMeters: distanceMeters,
      points: points,
    );
  }
}

void main() {
  test('loadDogsが成功するとdogsが入りisLoadingがfalseになる', () async {
    final repo = DogsRepository(client: _StubApiClient(dogsResult: [_leo]));

    final future = repo.loadDogs();
    expect(repo.isLoading, isTrue);
    await future;

    expect(repo.isLoading, isFalse);
    expect(repo.error, isNull);
    expect(repo.dogs, [_leo]);
  });

  test('loadDogsが失敗するとerrorが入りdogsは空のまま', () async {
    final repo = DogsRepository(
        client: _StubApiClient(dogsError: Exception('network down')));

    await repo.loadDogs();

    expect(repo.isLoading, isFalse);
    expect(repo.error, isNotNull);
    expect(repo.dogs, isEmpty);
  });

  test('addRecordは該当する犬のrecordsだけを更新する', () async {
    final newRecord = HealthRecord(
        id: '1', type: 'vet', label: '定期健診', date: DateTime(2026, 8, 27));
    final repo = DogsRepository(
      client: _StubApiClient(dogsResult: [_leo], createRecordResult: newRecord),
    );
    await repo.loadDogs();

    await repo.addRecord(dogId: 'leo', type: 'vet', label: '定期健診');

    expect(repo.dogs.single.records, [newRecord]);
  });

  test('fetchUpcomingが失敗してもdogsは読み込まれる', () async {
    final repo = DogsRepository(
      client: _StubApiClient(dogsResult: [_leo], upcomingError: Exception('404')),
    );

    await repo.loadDogs();

    expect(repo.error, isNull);
    expect(repo.dogs, [_leo]);
    expect(repo.upcoming, isEmpty);
  });

  test('loadDogsは今後の予定も読み込む', () async {
    final item = UpcomingItem(
        id: '1',
        dogId: 'leo',
        label: '定期健診',
        date: DateTime(2026, 9, 1),
        type: RecordType.vet);
    final repo = DogsRepository(
      client: _StubApiClient(dogsResult: [_leo], upcomingResult: [item]),
    );

    await repo.loadDogs();

    expect(repo.upcoming, [item]);
  });

  test('addUpcomingは日付順を保って追加する', () async {
    final earlier = UpcomingItem(
        id: '1',
        dogId: 'leo',
        label: '早い予定',
        date: DateTime(2026, 9, 1),
        type: RecordType.vet);
    final later = UpcomingItem(
        id: '2',
        dogId: 'leo',
        label: '遅い予定',
        date: DateTime(2026, 9, 10),
        type: RecordType.grooming);
    final repo = DogsRepository(
      client: _StubApiClient(
        dogsResult: [_leo],
        upcomingResult: [later],
        createUpcomingResult: earlier,
      ),
    );
    await repo.loadDogs();

    await repo.addUpcoming(
      dogId: 'leo',
      type: RecordType.vet,
      label: '早い予定',
      date: DateTime(2026, 9, 1),
    );

    expect(repo.upcoming, [earlier, later]);
  });

  test('updateDogは該当する犬のプロフィールだけを更新する', () async {
    final repo = DogsRepository(client: _StubApiClient(dogsResult: [_leo]));
    await repo.loadDogs();

    await repo.updateDog(
      dogId: 'leo',
      name: 'レオ2',
      breed: 'トイプードル',
      color: 'ホワイト',
      birthYear: 2020,
    );

    final updated = repo.dogs.single;
    expect(updated.id, 'leo');
    expect(updated.name, 'レオ2');
    expect(updated.breed, 'トイプードル');
    expect(updated.color, 'ホワイト');
    expect(updated.birthYear, 2020);
    expect(updated.accent, _leo.accent); // accentはローカルの値を保持する
  });

  test('addDogは末尾に犬を追加する', () async {
    const created = Dog(
      id: 'noa',
      name: 'ノア',
      breed: 'スタンダードプードル',
      color: 'ブラック',
      birthYear: 2022,
      accent: Color(0xFF000000), // クライアントからの仮の色。リポジトリ側で上書きされる
      weightHistory: [],
      records: [],
    );
    final repo = DogsRepository(
      client: _StubApiClient(dogsResult: [_leo], createDogResult: created),
    );
    await repo.loadDogs();

    await repo.addDog(name: 'ノア', breed: 'スタンダードプードル', color: 'ブラック', birthYear: 2022);

    expect(repo.dogs.map((d) => d.id), ['leo', 'noa']);
    expect(repo.dogs.last.name, 'ノア');
  });

  test('notifyListenersがloadDogsの開始と終了で呼ばれる', () async {
    final repo = DogsRepository(client: _StubApiClient(dogsResult: [_leo]));
    var notifyCount = 0;
    repo.addListener(() => notifyCount++);

    await repo.loadDogs();

    expect(notifyCount, 2); // 開始時(isLoading=true)と終了時
  });
}
