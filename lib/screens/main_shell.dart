import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../data/dogs_repository.dart';
import '../theme/app_theme.dart';
import 'ai_check_screen.dart';
import 'dogs_screen.dart';
import 'home_screen.dart';
import 'records_screen.dart';

class MainShell extends StatefulWidget {
  final DogsRepository repository;

  /// テストからAICheckScreenの画像選択をフェイクに差し替えるために公開している。
  final Future<Uint8List?> Function(BuildContext context)? pickImage;

  const MainShell({super.key, required this.repository, this.pickImage});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tabIndex = 0;
  final _dogsTabKey = GlobalKey<DogsTabScreenState>();

  static const _tabs = [
    (label: 'ホーム', icon: Icons.home_outlined, activeIcon: Icons.home),
    (label: '犬たち', icon: Icons.pets_outlined, activeIcon: Icons.pets),
    (label: '健康チェック', icon: Icons.camera_alt_outlined, activeIcon: Icons.camera_alt),
    (label: '記録', icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt),
  ];

  @override
  void initState() {
    super.initState();
    widget.repository.loadDogs();
  }

  void _openDogFromHome(String dogId) {
    setState(() => _tabIndex = 1);
    // フレーム描画後にDogsTabScreenのstateへ反映する
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dogsTabKey.currentState?.openDog(dogId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.repository,
          builder: (context, _) {
            final repo = widget.repository;
            if (repo.isLoading && repo.dogs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (repo.error != null && repo.dogs.isEmpty) {
              return _LoadErrorView(
                error: repo.error!,
                onRetry: repo.loadDogs,
              );
            }
            if (repo.dogs.isEmpty) {
              return const Center(
                child: Text('登録されている犬がいません', style: AppText.bodySoft),
              );
            }
            return IndexedStack(
              index: _tabIndex,
              children: [
                HomeScreen(dogs: repo.dogs, onSelectDog: _openDogFromHome),
                DogsTabScreen(key: _dogsTabKey, dogs: repo.dogs),
                AICheckScreen(
                  dogs: repo.dogs,
                  repository: repo,
                  pickImage: widget.pickImage ?? pickCheckImage,
                ),
                RecordsScreen(dogs: repo.dogs, repository: repo),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border(top: BorderSide(color: AppColors.ink.withValues(alpha: 0.08))),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final active = i == _tabIndex;
              return InkWell(
                onTap: () => setState(() => _tabIndex = i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? tab.activeIcon : tab.icon,
                        size: 20,
                        color: active ? AppColors.ink : AppColors.inkSoft,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 9,
                          color: active ? AppColors.ink : AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _LoadErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: AppColors.inkSoft),
            const SizedBox(height: 12),
            const Text('dogapp-apiに接続できませんでした', style: AppText.body, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('$error', style: AppText.caption, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('再試行')),
          ],
        ),
      ),
    );
  }
}
