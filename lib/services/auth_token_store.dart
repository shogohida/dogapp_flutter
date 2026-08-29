import 'package:flutter/foundation.dart';

/// ログイン中のJWTを保持するだけの薄い箱。DogappApiClientはこれを
/// (再構築なしで)読み続けることで、ログイン/ログアウトの度に
/// APIクライアントを作り直さずにAuthorizationヘッダーへ反映できる。
class AuthTokenStore extends ChangeNotifier {
  String? _token;

  String? get token => _token;

  void setToken(String? token) {
    _token = token;
    notifyListeners();
  }
}
