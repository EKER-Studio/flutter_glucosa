import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/enums/hba1c_unit.dart';
import '../../../../core/domain/utils/decimal_parser.dart';
import '../../../../core/domain/utils/glucose_converter.dart';
import '../../../../core/domain/utils/reading_validator.dart';
import '../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/presentation/utils/reading_validation_l10n.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/clamped_layout.dart';
import '../../../../core/presentation/widgets/form/delete_reading_dialog.dart';
import '../../../../core/presentation/widgets/form/reading_date_time_picker.dart';
import '../../../../core/presentation/widgets/form/reading_notes_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/user_profile_notifier.dart';
import '../../domain/entities/hba1c_reading.dart';
import '../providers/hba1c_reading_detail_notifier.dart';
import '../providers/hba1c_reading_list_notifier.dart';

/// Screen allowing users to create a new HbA1c reading or update/delete an existing one.
class AddEditHbA1cReadingScreen extends ConsumerStatefulWidget {
  /// The reading identifier when editing an existing reading; `null` when adding a new reading.
  final int? readingId;

  /// Creates an [AddEditHbA1cReadingScreen].
  const AddEditHbA1cReadingScreen({super.key, this.readingId});

  @override
  ConsumerState<AddEditHbA1cReadingScreen> createState() =>
      _AddEditHbA1cReadingScreenState();
}

class _AddEditHbA1cReadingScreenState
    extends ConsumerState<AddEditHbA1cReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDateTime;
  bool _isInitialized = false;
  bool _isSaving = false;

  bool get isEditMode => widget.readingId != null;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromReading(HbA1cReading reading, HbA1cUnit unit) {
    if (_isInitialized) return;
    _isInitialized = true;

    final String valueText;
    if (unit == HbA1cUnit.mmolMol) {
      valueText = GlucoseConverter.percentageToMmolMol(
        reading.readingPercentage,
      ).round().toString();
    } else {
      valueText = reading.readingPercentage.toString();
    }

    _valueController.text = valueText;
    _notesController.text = reading.notes ?? '';
    _selectedDateTime = reading.createdAt;
  }

  Future<void> _save(HbA1cUnit unit) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final rawValue = DecimalParser.parse(_valueController.text);
    if (rawValue == null) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.show(
        context,
        message: AppLocalizations.of(context)!.errorValidation,
        type: SnackBarType.error,
      );
      return;
    }
    final double percentage;
    if (unit == HbA1cUnit.mmolMol) {
      percentage = GlucoseConverter.mmolMolToPercentage(rawValue);
    } else {
      percentage = rawValue;
    }

    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final reading = HbA1cReading(
      id: widget.readingId ?? 0,
      readingPercentage: percentage,
      notes: notes,
      createdAt: _selectedDateTime,
    );

    final notifier = ref.read(hbA1cReadingListProvider.notifier);
    final (success, failure) = isEditMode
        ? await notifier.updateReading(reading)
        : await notifier.addReading(reading);

    if (!mounted) return;
    setState(() => _isSaving = false);

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      AppSnackBar.show(
        context,
        message: l10n.hba1cSavedSuccess,
        type: SnackBarType.success,
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      AppSnackBar.show(
        context,
        message: failure != null
            ? failure.toUserMessage(l10n)
            : l10n.genericError,
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await DeleteReadingDialog.show(
      context,
      title: l10n.deleteHba1c,
      message: l10n.deleteHba1cConfirm,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    final notifier = ref.read(hbA1cReadingListProvider.notifier);
    final (success, failure) = await notifier.deleteReading(widget.readingId!);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppSnackBar.show(
        context,
        message: l10n.hba1cDeletedSuccess,
        type: SnackBarType.success,
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      AppSnackBar.show(
        context,
        message: failure != null
            ? failure.toUserMessage(l10n)
            : l10n.genericError,
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);
    final preferredUnit =
        profileAsync.value?.preferredHbA1cUnit ?? HbA1cUnit.percentage;

    final title = isEditMode ? (l10n.editHba1c) : l10n.addHba1c;

    if (isEditMode) {
      // Wait for the profile so unit conversion in _populateFromReading
      // never runs against a fallback unit.
      if (profileAsync.isLoading) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const AppLoadingIndicator(),
        );
      }
      final detailAsync = ref.watch(
        hbA1cReadingDetailProvider(widget.readingId!),
      );
      return detailAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const Center(child: AppLoadingIndicator()),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(child: Text(l10n.genericError)),
        ),
        data: (reading) {
          if (reading == null) {
            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: Center(child: Text(l10n.errorNotFound)),
            );
          }
          _populateFromReading(reading, preferredUnit);
          return _buildScaffold(context, theme, l10n, preferredUnit, title);
        },
      );
    }

    return _buildScaffold(context, theme, l10n, preferredUnit, title);
  }

  Widget _buildScaffold(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    HbA1cUnit unit,
    String title,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deleteHba1c,
              onPressed: _isSaving ? null : _delete,
            ),
        ],
      ),
      body: ClampedLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.hba1c,
                    hintText: l10n.hba1cValueHint,
                    suffixText: unit.displayName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.biotech_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.errorValidation;
                    }
                    final numVal = DecimalParser.parse(val);
                    if (numVal == null || numVal <= 0) {
                      return l10n.errorValidation;
                    }
                    if (unit == HbA1cUnit.mmolMol) {
                      final error = ReadingValidator.validateHbA1cMmolMol(
                        numVal,
                      );
                      return ReadingValidationL10n.translate(error, l10n) ??
                          error;
                    }
                    final error = ReadingValidator.validateHbA1cPercentage(
                      numVal,
                    );
                    return ReadingValidationL10n.translate(error, l10n) ??
                        error;
                  },
                ),
                const SizedBox(height: 16),

                ReadingDateTimePicker(
                  selectedDateTime: _selectedDateTime,
                  onDateTimeChanged: (dt) =>
                      setState(() => _selectedDateTime = dt),
                ),
                const SizedBox(height: 16),

                ReadingNotesField(controller: _notesController),
                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: _isSaving ? null : () => _save(unit),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
