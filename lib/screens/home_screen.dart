import 'package:flutter/material.dart';
import '../data/dogs_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/dog.dart';
import '../theme/app_theme.dart';
import '../widgets/dog_avatar.dart';

class HomeScreen extends StatelessWidget {
  final List<Dog> dogs;
  final DogsRepository repository;
  final void Function(String dogId) onSelectDog;

  const HomeScreen({
    super.key,
    required this.dogs,
    required this.repository,
    required this.onSelectDog,
  });

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.upcoming, style: AppText.eyebrow),
              IconButton(
                onPressed: dogs.isEmpty
                    ? null
                    : () => _showAddUpcomingSheet(context, dogs, repository),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppColors.ink,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: l10n.addUpcoming,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _UpcomingTimeline(dogs: dogs, items: repository.upcoming),
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
    if (visibleItems.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(l10n.noUpcomingItems, style: AppText.bodySoft),
      );
    }
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

void _showAddUpcomingSheet(
    BuildContext context, List<Dog> dogs, DogsRepository repository) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) =>
        _AddUpcomingSheet(dogs: dogs, repository: repository),
  );
}

class _AddUpcomingSheet extends StatefulWidget {
  final List<Dog> dogs;
  final DogsRepository repository;

  const _AddUpcomingSheet({required this.dogs, required this.repository});

  @override
  State<_AddUpcomingSheet> createState() => _AddUpcomingSheetState();
}

class _AddUpcomingSheetState extends State<_AddUpcomingSheet> {
  late String _dogId = widget.dogs.first.id;
  RecordType _type = RecordType.vet;
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  final _noteController = TextEditingController();
  bool _saving = false;
  String? _error;

  Map<RecordType, String> _typeLabels(AppLocalizations l10n) => {
        RecordType.vaccine: l10n.recordTypeVaccine,
        RecordType.grooming: l10n.recordTypeGrooming,
        RecordType.vet: l10n.recordTypeVet,
        RecordType.medication: l10n.recordTypeMedication,
      };

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeLabels = _typeLabels(l10n);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(l10n.addUpcoming, style: AppText.displaySmall)),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _dogId,
            decoration: _fieldDecoration(),
            items: widget.dogs
                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                .toList(),
            onChanged: (v) => setState(() => _dogId = v!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<RecordType>(
            initialValue: _type,
            decoration: _fieldDecoration(),
            items: typeLabels.entries
                .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('upcomingNoteField'),
            controller: _noteController,
            decoration: _fieldDecoration(hint: l10n.noteOptional),
          ),
          const SizedBox(height: 10),
          InkWell(
            key: const Key('upcomingDateField'),
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: InputDecorator(
              decoration: _fieldDecoration(hint: l10n.date),
              child: Text(
                '${_date.year}/${_date.month}/${_date.day}',
                style: AppText.body,
              ),
            ),
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
              onPressed: _saving ? null : () => _save(l10n, typeLabels),
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
                  : Text(l10n.save, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
      AppLocalizations l10n, Map<RecordType, String> typeLabels) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final note = _noteController.text.trim();
    final label = note.isEmpty ? typeLabels[_type]! : note;
    try {
      await widget.repository.addUpcoming(
        dogId: _dogId,
        type: _type,
        label: label,
        date: _date,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = l10n.saveFailed('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
