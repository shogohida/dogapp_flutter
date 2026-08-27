import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../l10n/app_localizations.dart';
import '../models/dog.dart';
import '../theme/app_theme.dart';
import '../widgets/dog_avatar.dart';

class HomeScreen extends StatelessWidget {
  final List<Dog> dogs;
  final void Function(String dogId) onSelectDog;

  const HomeScreen({super.key, required this.dogs, required this.onSelectDog});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.welcomeBack, style: AppText.display),
          const SizedBox(height: 2),
          Text(l10n.healthRecordsSummary(dogs.length), style: AppText.bodySoft),
          const SizedBox(height: 20),
          Row(
            children: dogs
                .map((dog) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: dog == dogs.first ? 6 : 0,
                          left: dog == dogs.first ? 0 : 6,
                        ),
                        child: _DogCard(
                            dog: dog, onTap: () => onSelectDog(dog.id)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 28),
          Text(l10n.upcoming, style: AppText.eyebrow),
          const SizedBox(height: 10),
          _UpcomingTimeline(dogs: dogs, items: mockUpcoming),
        ],
      ),
    );
  }
}

class _DogCard extends StatelessWidget {
  final Dog dog;
  final VoidCallback onTap;

  const _DogCard({required this.dog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DogAvatar(dog: dog, size: 44),
            const SizedBox(height: 10),
            Text(dog.name, style: AppText.displaySmall),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!
                  .dogInfoLine(dog.color, dog.ageInYears(2026)),
              style: AppText.caption,
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '${dog.latestWeightKg}', style: AppText.mono),
                  const TextSpan(text: ' kg', style: AppText.monoCaption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTimeline extends StatelessWidget {
  final List<Dog> dogs;
  final List<UpcomingItem> items;

  const _UpcomingTimeline({required this.dogs, required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems =
        items.where((item) => dogs.any((d) => d.id == item.dogId)).toList();
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Column(
        children: visibleItems.map((item) {
          final dog = dogs.firstWhere((d) => d.id == item.dogId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14, right: 10),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.paperOuter,
                      border: Border.all(color: dog.accent, width: 2),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.ink.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        Icon(item.type.icon,
                            size: 18, color: AppColors.inkSoft),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.label,
                                  style: AppText.body,
                                  overflow: TextOverflow.ellipsis),
                              Text(dog.name, style: AppText.caption),
                            ],
                          ),
                        ),
                        Text(
                          '${item.date.month}/${item.date.day}',
                          style: AppText.monoCaption,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
