import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/utils/decimal_parser.dart';
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
import '../../domain/entities/ketone_reading.dart';
import '../providers/ketone_reading_detail_notifier.dart';
import '../providers/ketone_reading_list_notifier.dart';

/// Screen allowing users to create a new ketone reading or update/delete an existing one.
class AddEditKetoneReadingScreen extends ConsumerStatefulWidget {
  /// The reading identifier when editing an existing reading; `null` when adding a new reading.
  final int? readingId;

  /// Creates an [AddEditKetoneReadingScreen].
  const AddEditKetoneReadingScreen({super.key, this.readingId});

  @override
  ConsumerState<AddEditKetoneReadingScreen> createState() =>
      _AddEditKetoneReadingScreenState();
}

class _AddEditKetoneReadingScreenState
    extends ConsumerState<AddEditKetoneReadingScreen> {
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

  void _populateFromReading(KetoneReading reading) {
    if (_isInitialized) return;
    _isInitialized = true;

    _valueController.text = reading.readingMmolL.toString();
    _notesController.text = reading.notes ?? '';
    _selectedDateTime = reading.createdAt;
  }

  Future<void> _save() async {
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

    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final reading = KetoneReading(
      id: widget.readingId ?? 0,
      readingMmolL: rawValue,
      notes: notes,
      createdAt: _selectedDateTime,
    );

    final notifier = ref.read(ketoneReadingListProvider.notifier);
    final (success, failure) = isEditMode
        ? await notifier.updateReading(reading)
        : await notifier.addReading(reading);

    if (!mounted) return;
    setState(() => _isSaving = false);

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      AppSnackBar.show(
        context,
        message: l10n.ketonesSavedSuccess,
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
      title: l10n.deleteKetones,
      message: l10n.deleteKetonesConfirm,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    final notifier = ref.read(ketoneReadingListProvider.notifier);
    final (success, failure) = await notifier.deleteReading(widget.readingId!);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppSnackBar.show(
        context,
        message: l10n.ketonesDeletedSuccess,
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
    final l10n = AppLocalizations.of(context)!;

    final title = isEditMode ? (l10n.editKetones) : l10n.addKetones;

    if (isEditMode) {
      final detailAsync = ref.watch(
        ketoneReadingDetailProvider(widget.readingId!),
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
          _populateFromReading(reading);
          return _buildScaffold(context, Theme.of(context), l10n, title);
        },
      );
    }

    return _buildScaffold(context, Theme.of(context), l10n, title);
  }

  Widget _buildScaffold(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    String title,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deleteKetones,
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
                    labelText: l10n.ketones,
                    hintText: l10n.ketonesValueHint,
                    suffixText: 'mmol/L',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.science_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.errorValidation;
                    }
                    final numVal = DecimalParser.parse(val);
                    if (numVal == null) {
                      return l10n.errorValidation;
                    }
                    final error = ReadingValidator.validateKetones(numVal);
                    return ReadingValidationL10n.translate(error, l10n);
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
                  onPressed: _isSaving ? null : _save,
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
