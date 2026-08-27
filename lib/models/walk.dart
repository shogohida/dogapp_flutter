class GeoPoint {
  final double lat;
  final double lng;
  final DateTime timestamp;

  const GeoPoint(
      {required this.lat, required this.lng, required this.timestamp});

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp.toIso8601String(),
      };
}

class WalkRoute {
  final String id;
  final String dogId;
  final DateTime startedAt;
  final Duration duration;
  final double distanceMeters;
  final List<GeoPoint> points;

  const WalkRoute({
    required this.id,
    required this.dogId,
    required this.startedAt,
    required this.duration,
    required this.distanceMeters,
    required this.points,
  });

  factory WalkRoute.fromJson(Map<String, dynamic> json) => WalkRoute(
        id: json['id'] as String,
        dogId: json['dogId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        duration: Duration(seconds: json['durationSeconds'] as int),
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        points: (json['points'] as List<dynamic>? ?? [])
            .map((e) => GeoPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dogId': dogId,
        'startedAt': startedAt.toIso8601String(),
        'durationSeconds': duration.inSeconds,
        'distanceMeters': distanceMeters,
        'points': points.map((p) => p.toJson()).toList(),
      };
}

/// 過去の散歩履歴から集計した「よく歩くコース」1件分。
class RecommendedCourse {
  final WalkRoute sample;
  final int walkCount;
  final double averageDistanceMeters;

  const RecommendedCourse({
    required this.sample,
    required this.walkCount,
    required this.averageDistanceMeters,
  });
}
