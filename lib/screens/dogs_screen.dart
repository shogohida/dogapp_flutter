import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../data/dogs_repository.dart';
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
  final DogsRepository repository;

  /// テストからプロフィールカードのシェア処理をフェイクに差し替えるために公開している。
  final Future<void> Function(Uint8List pngBytes, String dogName)? shareImage;

  const DogsTabScreen({
    super.key,
    required this.dogs,
    required this.repository,
    this.shareImage,
  });

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
        repository: widget.repository,
        onBack: _back,
        shareImage: widget.shareImage ?? shareDogProfileImage,
      );
    }
    return DogsListScreen(
      dogs: widget.dogs,
      repository: widget.repository,
      onSelectDog: (id) => setState(() => _selectedDogId = id),
    );
  }
}

class DogsListScreen extends StatelessWidget {
  final List<Dog> dogs;
  final DogsRepository repository;
  final void Function(String dogId) onSelectDog;

  const DogsListScreen({
    super.key,
    required this.dogs,
    required this.repository,
    required this.onSelectDog,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.dogsTitle, style: AppText.display),
            IconButton(
              key: const Key('addDogButton'),
              onPressed: () => showAddDogSheet(context, repository),
              icon: const Icon(Icons.add_circle_outline, size: 22),
              color: AppColors.ink,
              tooltip: l10n.addDog,
            ),
          ],
        ),
        const SizedBox(height: 8),
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
  final DogsRepository repository;
  final VoidCallback onBack;
  final Future<void> Function(Uint8List pngBytes, String dogName) shareImage;

  const DogProfileScreen({
    super.key,
    required this.dog,
    required this.repository,
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
              key: const Key('editProfileButton'),
              onPressed: () =>
                  _showEditProfileSheet(context, dog, widget.repository),
              icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
              tooltip: l10n.editProfile,
            ),
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
                    Icon(iconForRecordType(r.type),
                        size: 18, color: AppColors.inkSoft),
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

void _showEditProfileSheet(
    BuildContext context, Dog dog, DogsRepository repository) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (context) => _EditProfileSheet(dog: dog, repository: repository),
  );
}

class _EditProfileSheet extends StatefulWidget {
  final Dog dog;
  final DogsRepository repository;

  const _EditProfileSheet({required this.dog, required this.repository});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _nameController = TextEditingController(text: widget.dog.name);
  late final _breedController = TextEditingController(text: widget.dog.breed);
  late final _colorController = TextEditingController(text: widget.dog.color);
  late final _birthYearController =
      TextEditingController(text: '${widget.dog.birthYear}');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  child: Text(l10n.editProfile, style: AppText.displaySmall)),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('editDogNameField'),
            controller: _nameController,
            decoration: _fieldDecoration(hint: l10n.dogNameLabel),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('editDogBreedField'),
            controller: _breedController,
            decoration: _fieldDecoration(hint: l10n.dogBreedLabel),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('editDogColorField'),
            controller: _colorController,
            decoration: _fieldDecoration(hint: l10n.dogColorLabel),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('editDogBirthYearField'),
            controller: _birthYearController,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(hint: l10n.dogBirthYearLabel),
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
              onPressed: _saving ? null : () => _save(l10n),
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

  Future<void> _save(AppLocalizations l10n) async {
    final name = _nameController.text.trim();
    final breed = _breedController.text.trim();
    final color = _colorController.text.trim();
    final birthYear = int.tryParse(_birthYearController.text.trim());
    if (name.isEmpty || breed.isEmpty || color.isEmpty) {
      setState(() => _error = l10n.profileFieldsRequired);
      return;
    }
    if (birthYear == null || birthYear < 1900 || birthYear > 2100) {
      setState(() => _error = l10n.invalidBirthYear);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.updateDog(
        dogId: widget.dog.id,
        name: name,
        breed: breed,
        color: color,
        birthYear: birthYear,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = l10n.updateDogFailed('$e'));
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

void showAddDogSheet(BuildContext context, DogsRepository repository) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (context) => _AddDogSheet(repository: repository),
  );
}

class _AddDogSheet extends StatefulWidget {
  final DogsRepository repository;

  const _AddDogSheet({required this.repository});

  @override
  State<_AddDogSheet> createState() => _AddDogSheetState();
}

class _AddDogSheetState extends State<_AddDogSheet> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _birthYearController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              Expanded(child: Text(l10n.addDog, style: AppText.displaySmall)),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('newDogNameField'),
            controller: _nameController,
            decoration: _fieldDecoration(hint: l10n.dogNameLabel),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('newDogBreedField'),
            controller: _breedController,
            decoration: _fieldDecoration(hint: l10n.dogBreedLabel),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('newDogColorField'),
            controller: _colorController,
            decoration: _fieldDecoration(hint: l10n.dogColorLabel),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('newDogBirthYearField'),
            controller: _birthYearController,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(hint: l10n.dogBirthYearLabel),
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
              onPressed: _saving ? null : () => _save(l10n),
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

  Future<void> _save(AppLocalizations l10n) async {
    final name = _nameController.text.trim();
    final breed = _breedController.text.trim();
    final color = _colorController.text.trim();
    final birthYear = int.tryParse(_birthYearController.text.trim());
    if (name.isEmpty || breed.isEmpty || color.isEmpty) {
      setState(() => _error = l10n.profileFieldsRequired);
      return;
    }
    if (birthYear == null || birthYear < 1900 || birthYear > 2100) {
      setState(() => _error = l10n.invalidBirthYear);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.addDog(
        name: name,
        breed: breed,
        color: color,
        birthYear: birthYear,
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
