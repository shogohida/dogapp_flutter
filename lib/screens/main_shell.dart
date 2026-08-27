import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/dogs_repository.dart';
import '../data/walks_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'ai_check_screen.dart';
import 'dogs_screen.dart';
import 'home_screen.dart';
import 'records_screen.dart';
import 'walk_screen.dart';

class MainShell extends StatefulWidget {
  final DogsRepository repository;
  final WalksRepository walksRepository;

  /// テストからAICheckScreenの画像/動画選択をフェイクに差し替えるために公開している。
  final Future<Uint8List?> Function(BuildContext context)? pickImage;
  final Future<XFile?> Function(BuildContext context)? pickVideo;

  const MainShell({
    super.key,
    required this.repository,
    required this.walksRepository,
    this.pickImage,
    this.pickVideo,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tabIndex = 0;
  final _dogsTabKey = GlobalKey<DogsTabScreenState>();

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
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      (label: l10n.tabHome, icon: Icons.home_outlined, activeIcon: Icons.home),
      (label: l10n.tabDogs, icon: Icons.pets_outlined, activeIcon: Icons.pets),
      (label: l10n.tabHealthCheck, icon: Icons.camera_alt_outlined, activeIcon: Icons.camera_alt),
      (label: l10n.tabRecords, icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt),
      (label: l10n.tabWalk, icon: Icons.directions_walk_outlined, activeIcon: Icons.directions_walk),
    ];

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
              return Center(
                child: Text(l10n.noDogsRegistered, style: AppText.bodySoft),
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
                  pickVideo: widget.pickVideo ?? pickCheckVideo,
                ),
                RecordsScreen(dogs: repo.dogs, repository: repo),
                WalkScreen(dogs: repo.dogs, repository: widget.walksRepository),
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
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: AppColors.inkSoft),
            const SizedBox(height: 12),
            Text(l10n.loadErrorTitle, style: AppText.body, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('$error', style: AppText.caption, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
