import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/dog.dart';
import '../services/dogapp_api_client.dart';

/// 画面側が参照する唯一のデータソース。
/// dogapp-apiへの実際のHTTP呼び出しは[DogappApiClient]に委譲し、
/// ここでは読み込み状態の管理と、取得済み[Dog]一覧の更新のみを行う。
class DogsRepository extends ChangeNotifier {
  DogsRepository({DogappApiClient? client})
      : _client = client ?? HttpDogappApiClient();

  final DogappApiClient _client;

  List<Dog> dogs = [];
  bool isLoading = false;
  Object? error;

  Future<void> loadDogs({String ownerId = ApiConfig.ownerId}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      dogs = await _client.fetchDogs(ownerId);
    } catch (e) {
      error = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<AICheckResult> runAiCheck({
    required String dogId,
    required Uint8List imageBytes,
  }) {
    return _client.runAiCheck(dogId: dogId, imageBytes: imageBytes);
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
    required RecordType type,
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
}
