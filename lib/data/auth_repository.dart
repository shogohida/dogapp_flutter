import '../models/user.dart';
import '../services/auth_token_store.dart';
import '../services/dogapp_api_client.dart';
import '../services/token_storage.dart';

/// signup/login/ログアウトと、端末再起動をまたいだセッション復元を管理する。
/// トークンそのものは[AuthTokenStore]に書き込み、DogappApiClientはそちらを
/// 読むので、ここでの状態変化がAPIクライアントに自動で反映される。
class AuthRepository {
  AuthRepository({
    required DogappApiClient client,
    required AuthTokenStore tokenStore,
    TokenStorage? storage,
  })  : _client = client,
        _tokenStore = tokenStore,
        _storage = storage ?? SecureTokenStorage();

  final DogappApiClient _client;
  final AuthTokenStore _tokenStore;
  final TokenStorage _storage;

  AppUser? currentUser;

  /// 端末に保存済みのトークンがあれば読み込み、ログイン状態を復元する。
  Future<void> restoreSession() async {
    final token = await _storage.read();
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
    await _storage.delete();
  }

  Future<void> _applyResult(AuthResult result) async {
    currentUser = result.user;
    _tokenStore.setToken(result.token);
    await _storage.write(result.token);
  }
}
