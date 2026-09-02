import 'package:geolocator/geolocator.dart';

/// 文字列ではなく理由を型で持たせることで、UI側でl10nのメッセージに
/// マッピングできるようにしている。
enum LocationFailure { serviceDisabled, permissionDenied }

class LocationServiceException implements Exception {
  final LocationFailure reason;
  LocationServiceException(this.reason);
}

/// geolocatorへの薄いラッパー。テストではネイティブの位置情報プラットフォーム
/// チャンネルが使えないため、フェイク実装に差し替えられるようにしている。
class LocationService {
  Future<void> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw LocationServiceException(LocationFailure.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationServiceException(LocationFailure.permissionDenied);
    }
  }

  Stream<Position> positionStream() {
    // distanceFilterは「前回の点からこの距離以上動かないと次のGPS点を
    // 発行しない」設定。stopRecording()はGPS点が2点未満だと保存しない
    // ため、値を大きくするほど記録に必要な最低歩行距離が伸びてしまう。
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 2),
    );
  }
}
