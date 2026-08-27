import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/dog.dart';
import '../theme/app_theme.dart';
import '../widgets/dog_avatar.dart';
import '../widgets/weight_chart.dart';

/// 犬一覧・プロフィールをまとめて扱う画面。
/// React版では `tab === "dogs"` の中で `selectedDogId` の有無により
/// 一覧⇄プロフィールを切り替えていたのと同じ構造をDartでも踏襲している。
class DogsTabScreen extends StatefulWidget {
  final List<Dog> dogs;

  const DogsTabScreen({super.key, required this.dogs});

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
      return DogProfileScreen(dog: dog, onBack: _back);
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

  const DogsListScreen({super.key, required this.dogs, required this.onSelectDog});

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
                    border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
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
                            Text(l10n.breedColorLine(dog.breed, dog.color), style: AppText.caption),
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

class DogProfileScreen extends StatelessWidget {
  final Dog dog;
  final VoidCallback onBack;

  const DogProfileScreen({super.key, required this.dog, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left, color: AppColors.ink),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            Text(dog.name, style: AppText.display),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            DogAvatar(dog: dog, size: 64),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dog.breed, style: AppText.caption),
                Text(l10n.dogInfoLine(dog.color, dog.ageInYears(2026)), style: AppText.caption),
              ],
            ),
          ],
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
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
