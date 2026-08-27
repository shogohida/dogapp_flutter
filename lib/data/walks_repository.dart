import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/walk.dart';
import '../services/dogapp_api_client.dart';
import '../services/location_service.dart';
import '../utils/geo.dart';

/// 犬ごとの散歩履歴の読み込みと、GPS記録中の状態を管理する。
/// 記録処理と保存処理を分離しているので、dogapp-apiの実際のエンドポイントが
/// 決まったときはDogappApiClient側だけを直せばよい。
class WalksRepository extends ChangeNotifier {
  WalksRepository({DogappApiClient? client, LocationService? locationService})
      : _client = client ?? HttpDogappApiClient(),
        _location = locationService ?? LocationService();

  final DogappApiClient _client;
  final LocationService _location;

  List<WalkRoute> walks = [];
  bool isLoading = false;
  Object? error;

  bool isRecording = false;
  Object? recordingError;
  List<GeoPoint> _currentPoints = [];
  DateTime? _startedAt;
  double _currentDistanceMeters = 0;
  StreamSubscription<Position>? _sub;

  List<GeoPoint> get currentPoints => List.unmodifiable(_currentPoints);
  double get currentDistanceMeters => _currentDistanceMeters;
  Duration get currentDuration => _startedAt == null
      ? Duration.zero
      : DateTime.now().difference(_startedAt!);

  Future<void> loadWalks(String dogId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      walks = await _client.fetchWalks(dogId);
    } catch (e) {
      error = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    recordingError = null;
    try {
      await _location.ensurePermission();
    } catch (e) {
      recordingError = e;
      notifyListeners();
      return;
    }
    _currentPoints = [];
    _currentDistanceMeters = 0;
    _startedAt = DateTime.now();
    isRecording = true;
    notifyListeners();

    _sub = _location.positionStream().listen((position) {
      final point = GeoPoint(
        lat: position.latitude,
        lng: position.longitude,
        timestamp: DateTime.now(),
      );
      if (_currentPoints.isNotEmpty) {
        final last = _currentPoints.last;
        _currentDistanceMeters +=
            haversineMeters(last.lat, last.lng, point.lat, point.lng);
      }
      _currentPoints.add(point);
      notifyListeners();
    });
  }

  /// 記録を確定してdogapp-apiに保存する。GPS点が少なすぎる場合はnullを返す。
  Future<WalkRoute?> stopRecording(String dogId) async {
    await _sub?.cancel();
    _sub = null;
    isRecording = false;

    if (_startedAt == null || _currentPoints.length < 2) {
      _resetCurrent();
      notifyListeners();
      return null;
    }

    final route = await _client.createWalk(
      dogId: dogId,
      startedAt: _startedAt!,
      duration: DateTime.now().difference(_startedAt!),
      distanceMeters: _currentDistanceMeters,
      points: _currentPoints,
    );
    walks = [route, ...walks];
    _resetCurrent();
    notifyListeners();
    return route;
  }

  void discardRecording() {
    _sub?.cancel();
    _sub = null;
    isRecording = false;
    _resetCurrent();
    notifyListeners();
  }

  void _resetCurrent() {
    _currentPoints = [];
    _currentDistanceMeters = 0;
    _startedAt = null;
  }

  /// 過去の散歩履歴から、よく歩くコースをおすすめする。
  /// 本格的な地図APIは使わず、開始地点が近い(約100m四方に丸めた座標が
  /// 一致する)散歩をまとめて、回数の多い順に並べるだけの簡易ロジック。
  List<RecommendedCourse> recommendedCourses({int limit = 3}) {
    final groups = <String, List<WalkRoute>>{};
    for (final walk in walks) {
      if (walk.points.isEmpty) continue;
      final start = walk.points.first;
      final key =
          '${start.lat.toStringAsFixed(3)},${start.lng.toStringAsFixed(3)}';
      groups.putIfAbsent(key, () => []).add(walk);
    }

    final courses = groups.values.map((group) {
      final sorted = [...group]
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      final totalDistance =
          group.fold<double>(0, (sum, w) => sum + w.distanceMeters);
      return RecommendedCourse(
        sample: sorted.first,
        walkCount: group.length,
        averageDistanceMeters: totalDistance / group.length,
      );
    }).toList();

    courses.sort((a, b) => b.walkCount.compareTo(a.walkCount));
    return courses.take(limit).toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
