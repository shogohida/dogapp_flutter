import 'package:dogapp/services/token_storage.dart';

/// 実プラットフォームのセキュアストレージ(Keychain/Keystore)なしで
/// restoreSession/login/logoutをテストするためのインメモリ実装。
class FakeTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> delete() async => _token = null;
}
