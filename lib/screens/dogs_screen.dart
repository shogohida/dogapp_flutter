import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../l10n/app_localizations.dart';
import '../models/dog.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dog_avatar.dart';
import '../widgets/dog_share_card.dart';
import '../widgets/weight_chart.dart';

/// 犬一覧・プロフィールをまとめて扱う画面。
/// React版では `tab === "dogs"` の中で `selectedDogId` の有無により
/// 一覧⇄プロフィールを切り替えていたのと同じ構造をDartでも踏襲している。
class DogsTabScreen extends StatefulWidget {
  final List<Dog> dogs;

  /// テストからプロフィールカードのシェア処理をフェイクに差し替えるために公開している。
  final Future<void> Function(Uint8List pngBytes, String dogName)? shareImage;

  const DogsTabScreen({super.key, required this.dogs, this.shareImage});

  @override
  State<DogsTabScreen> createState() => DogsTabScreenState();
}

class DogsTabScreenState extends State<DogsTabScreen> {
  String? _selectedDogId;

  /// ホーム画面のカードタップから、直接プロフィールを開くために
  /// 親(MainShell)から呼び出せるようにしている。
  void openDog(String dogId) {
    setState(() => _selectedDogId = dogId);
  }

  void _back() => setState(() => _selectedDogId = null);

  @override
  Widget build(BuildContext context) {
    if (_selectedDogId != null) {
      final dog = widget.dogs.firstWhere((d) => d.id == _selectedDogId);
      return DogProfileScreen(
        dog: dog,
        onBack: _back,
        shareImage: widget.shareImage ?? shareDogProfileImage,
      );
    }
    return DogsListScreen(
      dogs: widget.dogs,
      onSelectDog: (id) => setState(() => _selectedDogId = id),
    );
  }
}

class DogsListScreen extends StatelessWidget {
  final List<Dog> dogs;
  final void Function(String dogId) onSelectDog;

  const DogsListScreen(
      {super.key, required this.dogs, required this.onSelectDog});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Text(l10n.dogsTitle, style: AppText.display),
        const SizedBox(height: 16),
        ...dogs.map((dog) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onSelectDog(dog.id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.ink.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      DogAvatar(dog: dog),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dog.name, style: AppText.displaySmall),
                            Text(l10n.breedColorLine(dog.breed, dog.color),
                                style: AppText.caption),
                          ],
                        ),
                      ),
                      Text('${dog.latestWeightKg}kg', style: AppText.mono),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class DogProfileScreen extends StatefulWidget {
  final Dog dog;
  final VoidCallback onBack;
  final Future<void> Function(Uint8List pngBytes, String dogName) shareImage;

  const DogProfileScreen({
    super.key,
    required this.dog,
    required this.onBack,
    required this.shareImage,
  });

  @override
  State<DogProfileScreen> createState() => _DogProfileScreenState();
}

class _DogProfileScreenState extends State<DogProfileScreen> {
  final _shareCardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sharing = true);
    try {
      final boundary = _shareCardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      await widget.shareImage(
        byteData!.buffer.asUint8List(),
        widget.dog.name,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shareFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dog = widget.dog;
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.chevron_left, color: AppColors.ink),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            Expanded(child: Text(dog.name, style: AppText.display)),
            IconButton(
              key: const Key('shareProfileButton'),
              onPressed: _sharing ? null : _share,
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share, color: AppColors.ink),
              tooltip: l10n.shareProfile,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: RepaintBoundary(
            key: _shareCardKey,
            child: DogShareCard(dog: dog),
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.weightHistory, style: AppText.eyebrow),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
          ),
          child: WeightChart(entries: dog.weightHistory, accent: dog.accent),
        ),
        const SizedBox(height: 24),
        Text(l10n.recordsTitle, style: AppText.eyebrow),
        const SizedBox(height: 8),
        ...dog.records.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Icon(r.type.icon, size: 18, color: AppColors.inkSoft),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r.label, style: AppText.body)),
                    Text(
                      '${r.date.month}/${r.date.day}',
                      style: AppText.monoCaption,
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
