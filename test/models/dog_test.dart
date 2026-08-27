import 'package:dogapp/models/dog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WeightEntry.fromJson/toJsonは対称', () {
    const entry = WeightEntry(month: '3月', kg: 24.8);
    final restored = WeightEntry.fromJson(entry.toJson());
    expect(restored.month, entry.month);
    expect(restored.kg, entry.kg);
  });

  test('HealthRecord.fromJson/toJsonは対称', () {
    final record = HealthRecord(
      id: '1',
      type: RecordType.grooming,
      label: 'トリミング',
      date: DateTime.utc(2026, 8, 15),
    );
    final restored = HealthRecord.fromJson(record.toJson());
    expect(restored.id, record.id);
    expect(restored.type, record.type);
    expect(restored.label, record.label);
    expect(restored.date, record.date);
  });

  test('Dog.fromJson/toJsonは対称(accentは表示専用なので引数で渡す)', () {
    final dog = Dog(
      id: 'leo',
      name: 'レオ',
      breed: 'スタンダードプードル',
      color: 'アプリコット',
      birthYear: 2021,
      accent: Colors.orange,
      weightHistory: const [WeightEntry(month: '3月', kg: 24.8)],
      records: [
        HealthRecord(id: '1', type: RecordType.vet, label: '定期健診', date: DateTime.utc(2026, 8, 15)),
      ],
    );
    final restored = Dog.fromJson(dog.toJson(), accent: Colors.blue);

    expect(restored.id, dog.id);
    expect(restored.name, dog.name);
    expect(restored.birthYear, dog.birthYear);
    expect(restored.weightHistory.single.kg, 24.8);
    expect(restored.records.single.label, '定期健診');
    expect(restored.accent, Colors.blue); // accentはJSONに含まれず呼び出し側が決める
  });

  test('Dog.copyWithRecordsは他のフィールドを変えずrecordsだけ差し替える', () {
    const dog = Dog(
      id: 'leo',
      name: 'レオ',
      breed: 'スタンダードプードル',
      color: 'アプリコット',
      birthYear: 2021,
      accent: Colors.orange,
      weightHistory: [],
      records: [],
    );
    final newRecord = HealthRecord(id: '1', type: RecordType.vaccine, label: 'ワクチン', date: DateTime.utc(2026, 1, 1));

    final updated = dog.copyWithRecords([newRecord]);

    expect(updated.id, dog.id);
    expect(updated.name, dog.name);
    expect(updated.records, [newRecord]);
    expect(dog.records, isEmpty); // 元のDogはimmutableのまま
  });

  test('AICheckResult.fromJson', () {
    final result = AICheckResult.fromJson({
      'level': 'concern',
      'title': '赤み・脱毛が疑われます',
      'detail': '動物病院での診察をおすすめします',
    });
    expect(result.level, AICheckLevel.concern);
    expect(result.title, '赤み・脱毛が疑われます');
  });
}
