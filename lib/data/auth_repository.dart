import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/auth_token_store.dart';
import '../services/dogapp_api_client.dart';

const _tokenPrefsKey = 'authToken';

/// signup/login/ログアウトと、端末再起動をまたいだセッション復元を管理する。
/// トークンそのものは[AuthTokenStore]に書き込み、DogappApiClientはそちらを
/// 読むので、ここでの状態変化がAPIクライアントに自動で反映される。
class AuthRepository {
  AuthRepository({required DogappApiClient client, required AuthTokenStore tokenStore})
      : _client = client,
        _tokenStore = tokenStore;

  final DogappApiClient _client;
  final AuthTokenStore _tokenStore;

  AppUser? currentUser;

  /// 端末に保存済みのトークンがあれば読み込み、ログイン状態を復元する。
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenPrefsKey);
    if (token != null) {
      _tokenStore.setToken(token);
    }
  }

  Future<void> signup({required String email, required String password}) async {
    final result = await _client.signup(email: email, password: password);
    await _applyResult(result);
  }

  Future<void> login({required String email, required String password}) async {
    final result = await _client.login(email: email, password: password);
    await _applyResult(result);
  }

  Future<void> logout() async {
    currentUser = null;
    _tokenStore.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefsKey);
  }

  Future<void> _applyResult(AuthResult result) async {
    currentUser = result.user;
    _tokenStore.setToken(result.token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefsKey, result.token);
  }
}
