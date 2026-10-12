import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/domain/enums/glucose_unit.dart';
import '../../../../core/domain/enums/meal_context.dart';
import '../../../../core/domain/utils/glucose_converter.dart';
import '../../../../core/domain/utils/meal_context_detector.dart';
import '../../../../core/domain/utils/reading_validator.dart';
import '../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/presentation/utils/reading_validation_l10n.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/clamped_layout.dart';
import '../../../../core/presentation/widgets/form/delete_reading_dialog.dart';
import '../../../../core/presentation/widgets/form/reading_date_time_picker.dart';
import '../../../../core/presentation/widgets/form/reading_notes_field.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/user_profile_notifier.dart';
import '../../domain/entities/ble_saved_device.dart';
import '../../domain/entities/glucose_reading.dart';
import '../extensions/glucose_status_ui_extension.dart';
import '../providers/glucose_reading_detail_notifier.dart';
import '../providers/glucose_reading_list_notifier.dart';
import '../providers/saved_ble_device_notifier.dart';

/// Screen allowing users to create a new glucose reading or update/delete an existing one.
class AddEditGlucoseReadingScreen extends ConsumerStatefulWidget {
  /// The reading identifier when editing an existing reading; `null` when adding a new reading.
  final int? readingId;

  /// Creates an [AddEditGlucoseReadingScreen].
  const AddEditGlucoseReadingScreen({super.key, this.readingId});

  @override
  ConsumerState<AddEditGlucoseReadingScreen> createState() =>
      _AddEditGlucoseReadingScreenState();
}

class _AddEditGlucoseReadingScreenState
    extends ConsumerState<AddEditGlucoseReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  late MealContext _selectedContext;
  late DateTime _selectedDateTime;
  bool _isInitialized = false;
  bool _isSaving = false;

  bool get isEditMode => widget.readingId != null;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
    _selectedContext = MealContextDetector.detect(_selectedDateTime);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromReading(GlucoseReading reading, GlucoseUnit unit) {
    if (_isInitialized) return;
    _isInitialized = true;

    final String displayValue;
    if (unit == GlucoseUnit.mmolL) {
      displayValue = GlucoseConverter.mgDlToMmolL(
        reading.readingMgDl,
      ).toStringAsFixed(1);
    } else {
      displayValue = reading.readingMgDl.toString();
    }

    _valueController.text = displayValue;
    _selectedContext = reading.mealContext;
    _selectedDateTime = reading.createdAt;
    _notesController.text = reading.notes ?? '';
  }

  Future<void> _onSave(GlucoseUnit preferredUnit) async {
    if (!_formKey.currentState!.validate()) return;

    final rawText = _valueController.text.trim().replaceAll(',', '.');
    final numValue = double.tryParse(rawText);
    if (numValue == null) return;

    final int mgDl;
    if (preferredUnit == GlucoseUnit.mmolL) {
      mgDl = GlucoseConverter.mmolLToMgDl(numValue);
    } else {
      mgDl = numValue.round();
    }

    final validationError = ReadingValidator.validateGlucoseMgDl(mgDl);
    if (validationError != null) {
      final l10n = AppLocalizations.of(context)!;
      AppSnackBar.show(
        context,
        message:
            ReadingValidationL10n.translate(validationError, l10n) ??
            validationError,
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context)!;
    final notesText = _notesController.text.trim();

    final reading = GlucoseReading(
      id: widget.readingId ?? 0,
      readingMgDl: mgDl,
      mealContext: _selectedContext,
      notes: notesText.isEmpty ? null : notesText,
      createdAt: _selectedDateTime,
    );

    final (success, failure) = isEditMode
        ? await ref
              .read(glucoseReadingListProvider.notifier)
              .updateReading(reading)
        : await ref
              .read(glucoseReadingListProvider.notifier)
              .addReading(reading);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppSnackBar.show(
        context,
        message: isEditMode
            ? l10n.glucoseReadingUpdated
            : l10n.glucoseReadingAdded,
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
            : (isEditMode
                  ? l10n.failedToUpdateGlucoseReading
                  : l10n.failedToAddGlucoseReading),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _onDelete() async {
    if (!isEditMode) return;

    final l10n = AppLocalizations.of(context)!;
    final confirm = await DeleteReadingDialog.show(
      context,
      title: l10n.deleteReadingConfirmationTitle,
      message: l10n.deleteReadingConfirmationMessage,
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    final (success, failure) = await ref
        .read(glucoseReadingListProvider.notifier)
        .deleteReading(widget.readingId!);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppSnackBar.show(
        context,
        message: l10n.glucoseReadingDeleted,
        type: SnackBarType.info,
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      AppSnackBar.show(
        context,
        message: failure != null
            ? failure.toUserMessage(l10n)
            : l10n.failedToDeleteGlucoseReading,
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);
    final preferredUnit =
        profileAsync.value?.preferredGlucoseUnit ?? GlucoseUnit.mgDl;

    final savedDevice = ref.watch(savedBleDeviceProvider);

    if (isEditMode) {
      // Wait for the profile so unit conversion in _populateFromReading
      // never runs against a fallback unit.
      if (profileAsync.isLoading) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.editGlucoseReading)),
          body: const Center(child: AppLoadingIndicator()),
        );
      }
      final detailAsync = ref.watch(
        glucoseReadingDetailProvider(widget.readingId!),
      );

      return detailAsync.when(
        data: (reading) {
          if (reading == null) {
            return Scaffold(
              appBar: AppBar(title: Text(l10n.editGlucoseReading)),
              body: Center(child: Text(l10n.errorNotFound)),
            );
          }
          _populateFromReading(reading, preferredUnit);
          return _buildFormScaffold(
            context,
            l10n,
            preferredUnit,
            savedDevice: savedDevice,
          );
        },
        loading: () => Scaffold(
          appBar: AppBar(title: Text(l10n.editGlucoseReading)),
          body: const Center(child: AppLoadingIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: Text(l10n.editGlucoseReading)),
          body: Center(child: Text(l10n.genericError)),
        ),
      );
    }

    return _buildFormScaffold(
      context,
      l10n,
      preferredUnit,
      savedDevice: savedDevice,
    );
  }

  Widget _buildFormScaffold(
    BuildContext context,
    AppLocalizations l10n,
    GlucoseUnit preferredUnit, {
    BleSavedDevice? savedDevice,
  }) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? l10n.editGlucoseReading : l10n.addGlucoseReading,
        ),
        actions: [
          if (!isEditMode)
            IconButton(
              icon: const Icon(Icons.bluetooth),
              tooltip: l10n.bleGlucoseSyncTitle,
              onPressed: () => context.push(AppRoute.bleGlucoseSync.path),
            ),
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deleteGlucose,
              onPressed: _isSaving ? null : _onDelete,
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
                if (!isEditMode && savedDevice != null) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.bluetooth_connected),
                    label: Text(l10n.bleSyncFrom(savedDevice.name)),
                    onPressed: () => context.push(AppRoute.bleGlucoseSync.path),
                  ),
                  const SizedBox(height: 16),
                ],
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
                    labelText: l10n.glucoseReadingValue,
                    hintText: l10n.glucoseValueHint,
                    suffixText: preferredUnit.displayName,
                    prefixIcon: const Icon(Icons.water_drop_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.errorValidation;
                    }
                    final parsed = double.tryParse(
                      value.trim().replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed <= 0) {
                      return l10n.errorValidation;
                    }

                    final int mgDl = preferredUnit == GlucoseUnit.mmolL
                        ? GlucoseConverter.mmolLToMgDl(parsed)
                        : parsed.round();

                    return ReadingValidationL10n.translate(
                      ReadingValidator.validateGlucoseMgDl(mgDl),
                      l10n,
                    );
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<MealContext>(
                  initialValue: _selectedContext,
                  decoration: InputDecoration(
                    labelText: l10n.mealContext,
                    prefixIcon: const Icon(Icons.restaurant_outlined),
                  ),
                  items: MealContext.values.map((ctx) {
                    return DropdownMenuItem(
                      value: ctx,
                      child: Text(ctx.localizedName(l10n)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedContext = val);
                    }
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
                  icon: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.save),
                  onPressed: _isSaving ? null : () => _onSave(preferredUnit),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
