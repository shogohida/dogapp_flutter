import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'data/dogs_repository.dart';
import 'screens/main_shell.dart';
import 'services/dogapp_api_client.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DogHealthApp());
}

class DogHealthApp extends StatelessWidget {
  /// テストからフェイクのAPIクライアント/画像選択を差し込めるようにしている
  /// (実ネットワークやネイティブプラグインに依存しないウィジェットテストのため)。
  final DogappApiClient? apiClient;
  final Future<Uint8List?> Function(BuildContext context)? pickImage;

  const DogHealthApp({super.key, this.apiClient, this.pickImage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '犬の健康管理',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: MainShell(
        repository: DogsRepository(client: apiClient),
        pickImage: pickImage,
      ),
    );
  }
}
