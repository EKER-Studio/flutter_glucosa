import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums/glucose_unit.dart';
import '../../../../core/domain/enums/hba1c_unit.dart';
import '../../../../core/domain/utils/glucose_converter.dart';
import '../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/presentation/widgets/clamped_layout.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/user_profile_notifier.dart';
import '../../domain/entities/hba1c_reading.dart';
import '../providers/hba1c_reading_list_notifier.dart';
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

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _hba1cController.clear();
      _isUpdating = false;
      setState(() {});
      return;
    }

    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      _isUpdating = false;
      setState(() {});
      return;
    }

    final glucoseMgDl = _glucoseUnit == GlucoseUnit.mmolL
        ? GlucoseConverter.mmolLToMgDl(parsed)
        : parsed;

    final estHbA1cPercentage = GlucoseConverter.glucoseToEstimatedHbA1c(
      glucoseMgDl,
    );

    final displayHbA1c = _hba1cUnit == HbA1cUnit.mmolMol
        ? GlucoseConverter.percentageToMmolMol(
            estHbA1cPercentage,
          ).toStringAsFixed(1)
        : estHbA1cPercentage.toStringAsFixed(2);

    _hba1cController.text = displayHbA1c;
    _isUpdating = false;
    setState(() {});
  }

  void _onHbA1cChanged(String text) {
    if (_isUpdating) return;
    _isUpdating = true;

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _glucoseController.clear();
      _isUpdating = false;
      setState(() {});
      return;
    }

    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      _isUpdating = false;
      setState(() {});
      return;
    }

    final hba1cPercentage = _hba1cUnit == HbA1cUnit.mmolMol
        ? GlucoseConverter.mmolMolToPercentage(parsed)
        : parsed;

    final estGlucoseMgDl = GlucoseConverter.hba1cToEstimatedGlucose(
      hba1cPercentage,
    );

    final displayGlucose = _glucoseUnit == GlucoseUnit.mmolL
        ? GlucoseConverter.mgDlToMmolL(estGlucoseMgDl).toStringAsFixed(1)
        : estGlucoseMgDl.round().toString();

    _glucoseController.text = displayGlucose;
    _isUpdating = false;
    setState(() {});
  }

  void _onGlucoseUnitChanged(GlucoseUnit newUnit) {
    if (_glucoseUnit == newUnit) return;
    final currentText = _glucoseController.text.trim();
    final parsed = double.tryParse(currentText.replaceAll(',', '.'));

    setState(() {
      _glucoseUnit = newUnit;
      if (parsed != null && parsed > 0) {
        if (newUnit == GlucoseUnit.mmolL) {
          _glucoseController.text = GlucoseConverter.mgDlToMmolL(
            parsed,
          ).toStringAsFixed(1);
        } else {
          _glucoseController.text = GlucoseConverter.mmolLToMgDl(
            parsed,
          ).toString();
        }
      }
    });
  }

  void _onHbA1cUnitChanged(HbA1cUnit newUnit) {
    if (_hba1cUnit == newUnit) return;
    final currentText = _hba1cController.text.trim();
    final parsed = double.tryParse(currentText.replaceAll(',', '.'));

    setState(() {
      _hba1cUnit = newUnit;
      if (parsed != null && parsed > 0) {
        if (newUnit == HbA1cUnit.mmolMol) {
          _hba1cController.text = GlucoseConverter.percentageToMmolMol(
            parsed,
          ).toStringAsFixed(1);
        } else {
          _hba1cController.text = GlucoseConverter.mmolMolToPercentage(
            parsed,
          ).toStringAsFixed(2);
        }
      }
    });
  }

  double? get _currentHbA1cPercentage {
    final text = _hba1cController.text.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;

    if (_hba1cUnit == HbA1cUnit.mmolMol) {
      return GlucoseConverter.mmolMolToPercentage(parsed);
    }
    return parsed;
  }

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
