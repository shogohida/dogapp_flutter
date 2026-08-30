import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'data/auth_repository.dart';
import 'data/dogs_repository.dart';
import 'data/walks_repository.dart';
import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/auth_token_store.dart';
import 'services/dogapp_api_client.dart';
import 'services/location_service.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DogHealthApp());
}

class DogHealthApp extends StatelessWidget {
  /// テストからフェイクのAPIクライアント/画像・動画選択/位置情報を差し込める
  /// ようにしている(実ネットワークやネイティブプラグインに依存しない
  /// ウィジェットテストのため)。
  final DogappApiClient? apiClient;
  final Future<Uint8List?> Function(BuildContext context)? pickImage;
  final Future<XFile?> Function(BuildContext context)? pickVideo;
  final Future<void> Function(Uint8List pngBytes, String dogName)? shareImage;
  final LocationService? locationService;

  /// テストからフェイクのトークン永続化に差し替えるためのオーバーライド。
  /// 実プラットフォームのセキュアストレージ(Keychain/Keystore)に依存せずに
  /// restoreSession/login/logoutのテストができるようにしている。
  final TokenStorage? tokenStorage;

  /// テストからログイン済み状態を再現するためのオーバーライド。
  /// 指定すると端末保存済みトークンの復元をスキップし、即座にこの
  /// トークンでログイン済みとして扱う。
  final String? initialToken;

  const DogHealthApp({
    super.key,
    this.apiClient,
    this.pickImage,
    this.pickVideo,
    this.shareImage,
    this.locationService,
    this.tokenStorage,
    this.initialToken,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _AppRoot(
        apiClient: apiClient,
        pickImage: pickImage,
        pickVideo: pickVideo,
        shareImage: shareImage,
        locationService: locationService,
        tokenStorage: tokenStorage,
        initialToken: initialToken,
      ),
    );
  }
}

/// ログイン状態に応じてLoginScreen⇄MainShellを切り替えるルート。
/// APIクライアントとトークンの保持はここで一度だけ組み立て、
/// ログイン/ログアウトのたびにAuthTokenStoreの通知で切り替わる。
class _AppRoot extends StatefulWidget {
  final DogappApiClient? apiClient;
  final Future<Uint8List?> Function(BuildContext context)? pickImage;
  final Future<XFile?> Function(BuildContext context)? pickVideo;
  final Future<void> Function(Uint8List pngBytes, String dogName)? shareImage;
  final LocationService? locationService;
  final TokenStorage? tokenStorage;
  final String? initialToken;

  const _AppRoot({
    this.apiClient,
    this.pickImage,
    this.pickVideo,
    this.shareImage,
    this.locationService,
    this.tokenStorage,
    this.initialToken,
  });

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final AuthTokenStore _tokenStore = AuthTokenStore();
  late final DogappApiClient _client = widget.apiClient ??
      HttpDogappApiClient(
        getToken: () => _tokenStore.token,
        // トークンをサーバーに拒否された(401)ら、無効なトークンのまま
        // 失敗し続けないよう自動でログアウトしてログイン画面に戻す。
        onUnauthorized: () => _authRepository.logout(),
      );
  late final AuthRepository _authRepository = AuthRepository(
    client: _client,
    tokenStore: _tokenStore,
    storage: widget.tokenStorage,
  );
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      _tokenStore.setToken(widget.initialToken);
      _restoring = false;
    } else {
      _authRepository.restoreSession().whenComplete(() {
        if (mounted) setState(() => _restoring = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedBuilder(
      animation: _tokenStore,
      builder: (context, _) {
        final token = _tokenStore.token;
        if (token == null) {
          return LoginScreen(authRepository: _authRepository);
        }
        // tokenをkeyにすることで、ログアウト→別ユーザーでログインした際に
        // MainShellとその配下のリポジトリが確実に作り直され、前のユーザーの
        // データが残らないようにしている。
        return MainShell(
          key: ValueKey(token),
          repository: DogsRepository(client: _client),
          walksRepository: WalksRepository(
              client: _client, locationService: widget.locationService),
          authRepository: _authRepository,
          pickImage: widget.pickImage,
          pickVideo: widget.pickVideo,
          shareImage: widget.shareImage,
        );
      },
    );
  }
}
