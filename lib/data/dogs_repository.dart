import 'package:flutter/foundation.dart';

import '../models/dog.dart';
import '../services/dogapp_api_client.dart';
import '../theme/app_theme.dart';

/// 画面側が参照する唯一のデータソース。
/// dogapp-apiへの実際のHTTP呼び出しは[DogappApiClient]に委譲し、
/// ここでは読み込み状態の管理と、取得済み[Dog]一覧の更新のみを行う。
class DogsRepository extends ChangeNotifier {
  DogsRepository({DogappApiClient? client})
      : _client = client ?? HttpDogappApiClient();

  final DogappApiClient _client;

  List<Dog> dogs = [];
  List<UpcomingItem> upcoming = [];
  bool isLoading = false;
  Object? error;

  Future<void> loadDogs() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      dogs = await _client.fetchDogs();
    } catch (e) {
      error = e;
      isLoading = false;
      notifyListeners();
      return;
    }
    try {
      upcoming = await _client.fetchUpcoming();
    } catch (_) {
      // dogapp-apiがまだ今後の予定エンドポイントを持たない環境でも、
      // 犬一覧の表示自体は妨げない(ベストエフォート扱い)。
      upcoming = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> addDog({
    required String name,
    required String breed,
    required String color,
    required int birthYear,
  }) async {
    final created = await _client.createDog(
      name: name,
      breed: breed,
      color: color,
      birthYear: birthYear,
    );
    final dog = Dog(
      id: created.id,
      name: created.name,
      breed: created.breed,
      color: created.color,
      birthYear: created.birthYear,
      accent: AppColors.accentPalette[dogs.length % AppColors.accentPalette.length],
      weightHistory: created.weightHistory,
      records: created.records,
    );
    dogs = [...dogs, dog];
    notifyListeners();
  }

  Future<void> updateDog({
    required String dogId,
    required String name,
    required String breed,
    required String color,
    required int birthYear,
  }) async {
    await _client.updateDog(
      dogId: dogId,
      name: name,
      breed: breed,
      color: color,
      birthYear: birthYear,
    );
    final index = dogs.indexWhere((d) => d.id == dogId);
    if (index == -1) return;
    dogs[index] = dogs[index].copyWithProfile(
      name: name,
      breed: breed,
      color: color,
      birthYear: birthYear,
    );
    notifyListeners();
  }

  Future<void> addWeight({
    required String dogId,
    required String month,
    required double kg,
  }) async {
    final entry =
        await _client.addWeightEntry(dogId: dogId, month: month, kg: kg);
    final index = dogs.indexWhere((d) => d.id == dogId);
    if (index == -1) return;
    dogs[index] = dogs[index]
        .copyWithWeightHistory([...dogs[index].weightHistory, entry]);
    notifyListeners();
  }

  Future<AICheckResult> runAiCheck({
    required String dogId,
    required Uint8List imageBytes,
    required String bodyPart,
  }) {
    return _client.runAiCheck(
        dogId: dogId, imageBytes: imageBytes, bodyPart: bodyPart);
  }

  Future<AICheckResult> runGaitCheck({
    required String dogId,
    required Uint8List videoBytes,
    required String filename,
  }) {
    return _client.runGaitCheck(
        dogId: dogId, videoBytes: videoBytes, filename: filename);
  }

  Future<void> addRecord({
    required String dogId,
    required String type,
    required String label,
    double? cost,
  }) async {
    final record = await _client.createRecord(
      dogId: dogId,
      type: type,
      label: label,
      cost: cost,
    );
    final index = dogs.indexWhere((d) => d.id == dogId);
    if (index == -1) return;
    dogs[index] = dogs[index].copyWithRecords([record, ...dogs[index].records]);
    notifyListeners();
  }

  Future<void> addUpcoming({
    required String dogId,
    required RecordType type,
    required String label,
    required DateTime date,
  }) async {
    final item = await _client.createUpcoming(
      dogId: dogId,
      type: type,
      label: label,
      date: date,
    );
    upcoming = [...upcoming, item]..sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }
}
