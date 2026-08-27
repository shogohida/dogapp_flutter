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
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw LocationServiceException(LocationFailure.permissionDenied);
    }
  }

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    );
  }
}
