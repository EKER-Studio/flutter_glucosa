import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../domain/entities/cholesterol_reading.dart';
import '../providers/cholesterol_reading_detail_notifier.dart';
import '../providers/cholesterol_reading_list_notifier.dart';

/// Screen allowing users to create a new cholesterol reading or update/delete an existing one.
class AddEditCholesterolReadingScreen extends ConsumerStatefulWidget {
  /// The reading identifier when editing an existing reading; `null` when adding a new reading.
  final int? readingId;

  /// Creates an [AddEditCholesterolReadingScreen].
  const AddEditCholesterolReadingScreen({super.key, this.readingId});

  @override
  ConsumerState<AddEditCholesterolReadingScreen> createState() =>
      _AddEditCholesterolReadingScreenState();
}

class _AddEditCholesterolReadingScreenState
    extends ConsumerState<AddEditCholesterolReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final _ldlController = TextEditingController();
  final _hdlController = TextEditingController();
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
    _totalController.dispose();
    _ldlController.dispose();
    _hdlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromReading(CholesterolReading reading) {
    if (_isInitialized) return;
    _isInitialized = true;

    _totalController.text = reading.totalMgDl.toString();
    _ldlController.text = reading.ldlMgDl.toString();
    _hdlController.text = reading.hdlMgDl.toString();
    _notesController.text = reading.notes ?? '';
    _selectedDateTime = reading.createdAt;
  }

  String? _integerValidator(String? val, AppLocalizations l10n) {
    if (val == null || val.trim().isEmpty || int.tryParse(val.trim()) == null) {
      return l10n.errorValidation;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final total = int.tryParse(_totalController.text.trim());
    final ldl = int.tryParse(_ldlController.text.trim());
    final hdl = int.tryParse(_hdlController.text.trim());

    // Full clinical validation (total 50-500, LDL 20-400, HDL 10-150).
    final validationError = ReadingValidator.validateCholesterol(
      total: total,
      ldl: ldl,
      hdl: hdl,
    );
    if (validationError != null) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message:
            ReadingValidationL10n.translate(
              validationError,
              AppLocalizations.of(context)!,
            ) ??
            validationError,
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final reading = CholesterolReading(
      id: widget.readingId ?? 0,
      totalMgDl: total!,
      ldlMgDl: ldl!,
      hdlMgDl: hdl!,
      notes: notes,
      createdAt: _selectedDateTime,
    );

    final notifier = ref.read(cholesterolReadingListProvider.notifier);
    final (success, failure) = isEditMode
        ? await notifier.updateReading(reading)
        : await notifier.addReading(reading);

    if (!mounted) return;
    setState(() => _isSaving = false);

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      AppSnackBar.show(
        context,
        message: l10n.cholesterolSavedSuccess,
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
      title: l10n.deleteCholesterol,
      message: l10n.deleteCholesterolConfirm,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    final notifier = ref.read(cholesterolReadingListProvider.notifier);
    final (success, failure) = await notifier.deleteReading(widget.readingId!);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppSnackBar.show(
        context,
        message: l10n.cholesterolDeletedSuccess,
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

    final title = isEditMode ? (l10n.editCholesterol) : l10n.addCholesterol;

    if (isEditMode) {
      final detailAsync = ref.watch(
        cholesterolReadingDetailProvider(widget.readingId!),
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
              tooltip: l10n.deleteCholesterol,
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
                  controller: _totalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.totalCholesterolLabel,
                    hintText: l10n.cholesterolValueHint,
                    suffixText: 'mg/dL',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.bloodtype_outlined),
                  ),
                  validator: (val) => _integerValidator(val, l10n),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _ldlController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.ldlLabel,
                    hintText: l10n.cholesterolValueHint,
                    suffixText: 'mg/dL',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.trending_down_outlined),
                  ),
                  validator: (val) => _integerValidator(val, l10n),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _hdlController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.hdlLabel,
                    hintText: l10n.cholesterolValueHint,
                    suffixText: 'mg/dL',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.trending_up_outlined),
                  ),
                  validator: (val) => _integerValidator(val, l10n),
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
