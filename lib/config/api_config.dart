/// dogapp-api への接続設定。
///
/// ビルド時に `--dart-define` で上書きできるため、コード変更なしで
/// local / staging / production を切り替えられる。
/// 例: flutter run -d chrome --dart-define=API_BASE_URL=https://api.example.com
class ApiConfig {
  ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
