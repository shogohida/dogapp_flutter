import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/dogs_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/dog.dart';
import '../theme/app_theme.dart';

final _yenFormat = NumberFormat('#,##0');
String _formatYen(double amount) => '¥${_yenFormat.format(amount)}';

class RecordsScreen extends StatelessWidget {
  final List<Dog> dogs;
  final DogsRepository repository;

  const RecordsScreen(
      {super.key, required this.dogs, required this.repository});

  List<({HealthRecord record, Dog dog})> get _allRecords {
    final combined = <({HealthRecord record, Dog dog})>[];
    for (final dog in dogs) {
      for (final r in dog.records) {
        combined.add((record: r, dog: dog));
      }
    }
    combined.sort((a, b) => b.record.date.compareTo(a.record.date));
    return combined;
  }

  double get _totalCost => _allRecords.fold(
        0,
        (sum, item) => sum + (item.record.cost ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Text(l10n.recordsTitle, style: AppText.display),
        const SizedBox(height: 4),
        if (_totalCost > 0)
          Text(
            l10n.totalCost(_formatYen(_totalCost)),
            style: AppText.bodySoft,
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: dogs.isEmpty
                ? null
                : () => _showAddRecordSheet(context, dogs, repository),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addRecord, style: const TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(height: 16),
        ..._allRecords.map((item) => Padding(
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
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.dog.accent.withValues(alpha: 0.13),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconForRecordType(item.record.type),
                          size: 16, color: item.dog.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.record.label,
                              style: AppText.body,
                              overflow: TextOverflow.ellipsis),
                          Text(item.dog.name, style: AppText.caption),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (item.record.cost != null)
                          Text(
                            _formatYen(item.record.cost!),
                            style: AppText.mono,
                          ),
                        Text(
                          '${item.record.date.month}/${item.record.date.day}',
                          style: AppText.monoCaption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

void _showAddRecordSheet(
    BuildContext context, List<Dog> dogs, DogsRepository repository) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _AddRecordSheet(dogs: dogs, repository: repository),
  );
}

class _AddRecordSheet extends StatefulWidget {
  final List<Dog> dogs;
  final DogsRepository repository;

  const _AddRecordSheet({required this.dogs, required this.repository});

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  late String _dogId = widget.dogs.first.id;
  final _typeController = TextEditingController();
  final _noteController = TextEditingController();
  final _costController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _typeController.dispose();
    _noteController.dispose();
    _costController.dispose();
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
                  child: Text(l10n.addRecord, style: AppText.displaySmall)),
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
          TextField(
            key: const Key('recordTypeField'),
            controller: _typeController,
            decoration: _fieldDecoration(hint: l10n.recordTypeHint),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('recordNoteField'),
            controller: _noteController,
            decoration: _fieldDecoration(hint: l10n.noteOptional),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('recordCostField'),
            controller: _costController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDecoration(hint: l10n.costOptional),
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
    final type = _typeController.text.trim();
    if (type.isEmpty) {
      setState(() => _error = l10n.recordTypeRequired);
      return;
    }

    final costText = _costController.text.trim();
    double? cost;
    if (costText.isNotEmpty) {
      cost = double.tryParse(costText);
      if (cost == null || cost < 0) {
        setState(() => _error = l10n.invalidCost);
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final note = _noteController.text.trim();
    final label = note.isEmpty ? type : note;
    try {
      await widget.repository
          .addRecord(dogId: _dogId, type: type, label: label, cost: cost);
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
