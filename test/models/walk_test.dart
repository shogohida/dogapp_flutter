import 'package:dogapp/models/walk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GeoPoint.fromJson/toJsonは対称', () {
    final point = GeoPoint(
        lat: 35.681, lng: 139.767, timestamp: DateTime.utc(2026, 8, 27, 10));
    final restored = GeoPoint.fromJson(point.toJson());
    expect(restored.lat, point.lat);
    expect(restored.lng, point.lng);
    expect(restored.timestamp, point.timestamp);
  });

  test('WalkRoute.fromJson/toJsonは対称', () {
    final walk = WalkRoute(
      id: 'w1',
      dogId: 'leo',
      startedAt: DateTime.utc(2026, 8, 27, 10),
      duration: const Duration(minutes: 20),
      distanceMeters: 1500,
      points: [
        GeoPoint(
            lat: 35.0, lng: 139.0, timestamp: DateTime.utc(2026, 8, 27, 10))
      ],
    );
    final restored = WalkRoute.fromJson(walk.toJson());

    expect(restored.id, walk.id);
    expect(restored.dogId, walk.dogId);
    expect(restored.startedAt, walk.startedAt);
    expect(restored.duration, walk.duration);
    expect(restored.distanceMeters, walk.distanceMeters);
    expect(restored.points.single.lat, 35.0);
  });
}
