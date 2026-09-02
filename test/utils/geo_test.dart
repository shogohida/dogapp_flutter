import 'package:dogapp/utils/geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('haversineMeters', () {
    test('同じ座標なら距離は0', () {
      expect(haversineMeters(35.681, 139.767, 35.681, 139.767), 0);
    });

    test('緯度1度分の距離は約111.19km', () {
      // 経度を固定して緯度だけ1度動かすと、地球の半径から計算できる
      // 既知の距離(約111.19km)に近似できる。
      final distance = haversineMeters(35.0, 139.0, 36.0, 139.0);
      expect(distance, closeTo(111195, 5));
    });

    test('東京駅と新宿駅程度の距離感を返す', () {
      final distance =
          haversineMeters(35.6812, 139.7671, 35.6896, 139.7006);
      expect(distance, closeTo(6300, 300));
    });
  });
}
