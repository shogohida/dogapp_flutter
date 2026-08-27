import 'dart:typed_data';

import 'package:dogapp/data/dogs_repository.dart';
import 'package:dogapp/models/dog.dart';
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
  _StubApiClient({this.dogsResult, this.dogsError, this.createRecordResult});

  final List<Dog>? dogsResult;
  final Object? dogsError;
  final HealthRecord? createRecordResult;

  @override
  Future<List<Dog>> fetchDogs(String ownerId) async {
    if (dogsError != null) throw dogsError!;
    return dogsResult!;
  }

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
    required RecordType type,
    required String label,
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
        id: '1',
        type: RecordType.vet,
        label: '定期健診',
        date: DateTime(2026, 8, 27));
    final repo = DogsRepository(
      client: _StubApiClient(dogsResult: [_leo], createRecordResult: newRecord),
    );
    await repo.loadDogs();

    await repo.addRecord(dogId: 'leo', type: RecordType.vet, label: '定期健診');

    expect(repo.dogs.single.records, [newRecord]);
  });

  test('notifyListenersがloadDogsの開始と終了で呼ばれる', () async {
    final repo = DogsRepository(client: _StubApiClient(dogsResult: [_leo]));
    var notifyCount = 0;
    repo.addListener(() => notifyCount++);

    await repo.loadDogs();

    expect(notifyCount, 2); // 開始時(isLoading=true)と終了時
  });
}
