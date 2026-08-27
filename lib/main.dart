import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'data/dogs_repository.dart';
import 'data/walks_repository.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_shell.dart';
import 'services/dogapp_api_client.dart';
import 'services/location_service.dart';
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
  final LocationService? locationService;

  const DogHealthApp({
    super.key,
    this.apiClient,
    this.pickImage,
    this.pickVideo,
    this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainShell(
        repository: DogsRepository(client: apiClient),
        walksRepository: WalksRepository(
            client: apiClient, locationService: locationService),
        pickImage: pickImage,
        pickVideo: pickVideo,
      ),
    );
  }
}
