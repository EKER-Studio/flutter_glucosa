import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums/glucose_unit.dart';
import '../../../../core/domain/enums/hba1c_unit.dart';
import '../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/presentation/widgets/clamped_layout.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/user_profile_notifier.dart';
import '../../domain/entities/hba1c_reading.dart';
import '../providers/hba1c_reading_list_notifier.dart';
import '../utils/hba1c_calculator_coordinator.dart';
import '../widgets/calculator/average_glucose_input_card.dart';
import '../widgets/calculator/estimated_hba1c_input_card.dart';
import '../widgets/calculator/formula_explanation_card.dart';

/// Screen allowing bidirectional estimation between average glucose and glycated hemoglobin (HbA1c).
class HbA1cCalculatorScreen extends ConsumerStatefulWidget {
  /// Creates an [HbA1cCalculatorScreen].
  const HbA1cCalculatorScreen({super.key});

  @override
  ConsumerState<HbA1cCalculatorScreen> createState() =>
      _HbA1cCalculatorScreenState();
}

class _HbA1cCalculatorScreenState extends ConsumerState<HbA1cCalculatorScreen> {
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _hba1cController = TextEditingController();

  GlucoseUnit _glucoseUnit = GlucoseUnit.mgDl;
  HbA1cUnit _hba1cUnit = HbA1cUnit.percentage;

  bool _isUpdating = false;
  bool _isSaving = false;
  bool _hasInitializedUnits = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedUnits) {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        _glucoseUnit = profile.preferredGlucoseUnit;
        _hba1cUnit = profile.preferredHbA1cUnit;
      }
      _hasInitializedUnits = true;
    }
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    _hba1cController.dispose();
    super.dispose();
  }

  void _onGlucoseChanged(String text) {
    if (_isUpdating) return;
    _isUpdating = true;

    final result = HbA1cCalculatorCoordinator.calculateHbA1cFromGlucose(
      glucoseText: text,
      glucoseUnit: _glucoseUnit,
      hba1cUnit: _hba1cUnit,
    );

    _hba1cController.text = result;
    _isUpdating = false;
    setState(() {});
  }

  void _onHbA1cChanged(String text) {
    if (_isUpdating) return;
    _isUpdating = true;

    final result = HbA1cCalculatorCoordinator.calculateGlucoseFromHbA1c(
      hba1cText: text,
      hba1cUnit: _hba1cUnit,
      glucoseUnit: _glucoseUnit,
    );

    _glucoseController.text = result;
    _isUpdating = false;
    setState(() {});
  }

  void _onGlucoseUnitChanged(GlucoseUnit newUnit) {
    if (_glucoseUnit == newUnit) return;
    setState(() {
      _glucoseController.text =
          HbA1cCalculatorCoordinator.convertGlucoseDisplay(
            text: _glucoseController.text,
            oldUnit: _glucoseUnit,
            newUnit: newUnit,
          );
      _glucoseUnit = newUnit;
    });
  }

  void _onHbA1cUnitChanged(HbA1cUnit newUnit) {
    if (_hba1cUnit == newUnit) return;
    setState(() {
      _hba1cController.text = HbA1cCalculatorCoordinator.convertHbA1cDisplay(
        text: _hba1cController.text,
        oldUnit: _hba1cUnit,
        newUnit: newUnit,
      );
      _hba1cUnit = newUnit;
    });
  }

  double? get _currentHbA1cPercentage =>
      HbA1cCalculatorCoordinator.parseHbA1cPercentage(
        text: _hba1cController.text,
        hba1cUnit: _hba1cUnit,
      );

  Future<void> _saveReading() async {
    final hba1cPercentage = _currentHbA1cPercentage;
    if (hba1cPercentage == null || _isSaving) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      final (success, failure) = await ref
          .read(hbA1cReadingListProvider.notifier)
          .addReading(
            HbA1cReading(
              readingPercentage: hba1cPercentage,
              createdAt: DateTime.now(),
              notes: l10n.hba1cCalculatorAutoNote,
            ),
          );

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          AppSnackBar.show(
            context,
            message: l10n.hba1cReadingSaved,
            type: SnackBarType.success,
          );
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
    } catch (e, stack) {
      AppLogger.error(
        'Failed to save calculated HbA1c reading',
        error: e,
        stackTrace: stack,
        tag: 'HbA1cCalculatorScreen',
      );
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.show(
          context,
          message: l10n.genericError,
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canSave = _currentHbA1cPercentage != null && !_isSaving;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.hba1cCalculator)),
      body: ClampedLayout(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Text(
              l10n.hba1cCalculatorSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            AverageGlucoseInputCard(
              controller: _glucoseController,
              unit: _glucoseUnit,
              onUnitChanged: _onGlucoseUnitChanged,
              onChanged: _onGlucoseChanged,
            ),
            const SizedBox(height: 16),
            Center(
              child: Icon(
                Icons.swap_vert_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            EstimatedHbA1cInputCard(
              controller: _hba1cController,
              unit: _hba1cUnit,
              onUnitChanged: _onHbA1cUnitChanged,
              onChanged: _onHbA1cChanged,
            ),
            const SizedBox(height: 20),
            const FormulaExplanationCard(),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: canSave ? _saveReading : null,
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.bookmark_add_outlined),
              label: Text(l10n.saveAsHbA1cReading),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
