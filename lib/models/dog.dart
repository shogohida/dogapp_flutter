import 'package:flutter/material.dart';

/// 記録の種別。dogapp-api の model.RecordType と対応させている。
enum RecordType { vaccine, grooming, vet, medication, aiCheck }

extension RecordTypeIcon on RecordType {
  IconData get icon {
    switch (this) {
      case RecordType.vaccine:
        return Icons.vaccines_outlined;
      case RecordType.grooming:
        return Icons.content_cut;
      case RecordType.vet:
        return Icons.medical_services_outlined;
      case RecordType.medication:
        return Icons.calendar_month_outlined;
      case RecordType.aiCheck:
        return Icons.camera_alt_outlined;
    }
  }
}

class WeightEntry {
  final String month; // 表示用ラベル(例: "3月")
  final double kg;

  const WeightEntry({required this.month, required this.kg});

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      month: json['month'] as String,
      kg: (json['kg'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'month': month, 'kg': kg};
}

class HealthRecord {
  final String id;
  final RecordType type;
  final String label;
  final DateTime date;

  const HealthRecord({
    required this.id,
    required this.type,
    required this.label,
    required this.date,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'] as String,
      type: RecordType.values.byName(json['type'] as String),
      label: json['label'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'date': date.toIso8601String(),
      };
}

class Dog {
  final String id;
  final String name;
  final String breed;
  final String color;
  final int birthYear;
  final Color accent;
  final List<WeightEntry> weightHistory;
  final List<HealthRecord> records;

  const Dog({
    required this.id,
    required this.name,
    required this.breed,
    required this.color,
    required this.birthYear,
    required this.accent,
    required this.weightHistory,
    required this.records,
  });

  int ageInYears(int currentYear) => currentYear - birthYear;

  double get latestWeightKg =>
      weightHistory.isEmpty ? 0 : weightHistory.last.kg;

  /// dogapp-apiのレスポンスにはUI用の色は含まれないため、
  /// 一覧内の順序からアクセントカラーを決定的に割り当てる。
  factory Dog.fromJson(Map<String, dynamic> json, {required Color accent}) {
    return Dog(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: json['breed'] as String,
      color: json['color'] as String,
      birthYear: json['birthYear'] as int,
      accent: accent,
      weightHistory: (json['weightHistory'] as List<dynamic>? ?? [])
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      records: (json['records'] as List<dynamic>? ?? [])
          .map((e) => HealthRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'breed': breed,
        'color': color,
        'birthYear': birthYear,
        'weightHistory': weightHistory.map((e) => e.toJson()).toList(),
        'records': records.map((e) => e.toJson()).toList(),
      };

  Dog copyWithRecords(List<HealthRecord> records) => Dog(
        id: id,
        name: name,
        breed: breed,
        color: color,
        birthYear: birthYear,
        accent: accent,
        weightHistory: weightHistory,
        records: records,
      );
}

/// 予定(今後のリマインダー)
class UpcomingItem {
  final String id;
  final String dogId;
  final String label;
  final DateTime date;
  final RecordType type;

  const UpcomingItem({
    required this.id,
    required this.dogId,
    required this.label,
    required this.date,
    required this.type,
  });
}

/// AI健康チェックの結果レベル。安全のためこの3値に固定する
/// (dogapp-api の model.AICheckLevel と対応)。
enum AICheckLevel { normal, watch, concern }

class AICheckResult {
  final AICheckLevel level;
  final String title;
  final String detail;

  const AICheckResult({
    required this.level,
    required this.title,
    required this.detail,
  });

  factory AICheckResult.fromJson(Map<String, dynamic> json) {
    return AICheckResult(
      level: AICheckLevel.values.byName(json['level'] as String),
      title: json['title'] as String,
      detail: json['detail'] as String,
    );
  }
}
