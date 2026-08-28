import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/dog.dart';
import '../theme/app_theme.dart';
import 'dog_avatar.dart';

/// Instagram等にシェアする画像として書き出すための、犬プロフィールカード。
/// 画面のスクロール領域とは別に、常に同じサイズ(4:5)で描画することで
/// キャプチャした画像の見た目が実機の画面サイズに左右されないようにしている。
class DogShareCard extends StatelessWidget {
  final Dog dog;

  const DogShareCard({super.key, required this.dog});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 360,
      height: 450,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dog.accent.withValues(alpha: 0.25), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.appTitle, style: AppText.eyebrow),
          const Spacer(),
          DogAvatar(dog: dog, size: 96),
          const SizedBox(height: 20),
          Text(dog.name, style: AppText.display.copyWith(fontSize: 30)),
          const SizedBox(height: 6),
          Text(dog.breed, style: AppText.bodySoft),
          Text(l10n.dogInfoLine(dog.color, dog.ageInYears(2026)),
              style: AppText.bodySoft),
          const SizedBox(height: 20),
          _StatChip(
            label: l10n.currentWeight,
            value: '${dog.latestWeightKg}kg',
            accent: dog.accent,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatChip(
      {required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppText.mono),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}
