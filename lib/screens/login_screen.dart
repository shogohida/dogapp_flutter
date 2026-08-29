import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// 未ログイン時に表示する、ログイン/アカウント作成の切り替え可能な画面。
class LoginScreen extends StatefulWidget {
  final AuthRepository authRepository;

  const LoginScreen({super.key, required this.authRepository});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _signupMode = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (_signupMode && password.length < 8) {
      setState(() => _error = l10n.passwordTooShort);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_signupMode) {
        await widget.authRepository.signup(email: email, password: password);
      } else {
        await widget.authRepository.login(email: email, password: password);
      }
      // 成功時はAuthTokenStoreの通知でアプリのルートが自動的に
      // 切り替わるため、ここでは何もしなくてよい。
    } catch (e) {
      if (mounted) setState(() => _error = l10n.authFailed('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.appTitle, style: AppText.display),
                const SizedBox(height: 4),
                Text(_signupMode ? l10n.signupTitle : l10n.loginTitle,
                    style: AppText.eyebrow),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('emailField'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDecoration(hint: l10n.emailLabel),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('passwordField'),
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _fieldDecoration(hint: l10n.passwordLabel),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.concernBorder)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _submit(l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _signupMode ? l10n.signupButton : l10n.loginButton,
                            style: const TextStyle(fontSize: 13),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _signupMode = !_signupMode;
                              _error = null;
                            }),
                    child: Text(
                      _signupMode ? l10n.switchToLogin : l10n.switchToSignup,
                      style: AppText.caption,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.12)),
      ),
    );
  }
}
