class AppUser {
  final String id;
  final String email;

  const AppUser({required this.id, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
    );
  }
}

/// signup/loginのレスポンス(以降のリクエストで使うトークンとユーザー情報)。
class AuthResult {
  final String token;
  final AppUser user;

  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
