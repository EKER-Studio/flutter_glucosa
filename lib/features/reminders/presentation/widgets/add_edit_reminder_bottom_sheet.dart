import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums/metric_type.dart';
import '../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/presentation/utils/picker_helpers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_list_notifier.dart';

/// Modal bottom sheet enabling the creation or modification of a health measurement reminder.
class AddEditReminderBottomSheet extends ConsumerStatefulWidget {
  /// Existing reminder to edit, or `null` if creating a new reminder.
  final Reminder? existing;

  /// Creates an [AddEditReminderBottomSheet].
  const AddEditReminderBottomSheet({super.key, this.existing});

  /// Displays the modal bottom sheet for [existing] or a new reminder.
  static Future<void> show(BuildContext context, {Reminder? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddEditReminderBottomSheet(existing: existing),
    );
  }

  @override
  ConsumerState<AddEditReminderBottomSheet> createState() =>
      _AddEditReminderBottomSheetState();
}

class _AddEditReminderBottomSheetState
    extends ConsumerState<AddEditReminderBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _label;
  late MetricType _metricType;
  late TimeOfDay _time;
  late bool _isOneTime;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _label = widget.existing?.label ?? '';
    _metricType = widget.existing?.metricType ?? MetricType.glucose;
    _time = TimeOfDay(
      hour: widget.existing?.hourOfDay ?? 8,
      minute: widget.existing?.minute ?? 0,
    );
    _isOneTime = widget.existing?.isOneTime ?? false;
  }

  static String _metricTitle(MetricType type, AppLocalizations l10n) {
    return switch (type) {
      MetricType.glucose => l10n.glucose,
      MetricType.hba1c => l10n.hba1c,
      MetricType.bloodPressure => l10n.bloodPressure,
      MetricType.ketones => l10n.ketones,
      MetricType.cholesterol => l10n.cholesterol,
      MetricType.weight => l10n.weight,
    };
  }

  Future<void> _onSave() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      Navigator.of(context).pop();

      final reminder = Reminder(
        id: widget.existing?.id ?? 0,
        label: _label,
        metricType: _metricType,
        hourOfDay: _time.hour,
        minute: _time.minute,
        isActive: widget.existing?.isActive ?? true,
        isOneTime: _isOneTime,
      );

      final (success, failure) = _isEditing
          ? await ref
                .read(reminderListProvider.notifier)
                .updateReminder(reminder)
          : await ref.read(reminderListProvider.notifier).addReminder(reminder);

      if (mounted) {
        if (success) {
          AppSnackBar.show(
            context,
            message: l10n.reminderSavedSuccess,
            type: SnackBarType.success,
          );
        } else {
          AppSnackBar.show(
            context,
            message: failure != null
                ? failure.toUserMessage(l10n)
                : l10n.failedToSaveReminder,
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final timeFormatted = _time.format(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? l10n.editReminder : l10n.addReminder,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _label,
                autofocus: !_isEditing,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.reminderLabel,
                  hintText: l10n.reminderLabelHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.errorValidation;
                  }
                  return null;
                },
                onSaved: (val) => _label = val?.trim() ?? '',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_outlined),
                      label: Text('${l10n.reminderTime}: $timeFormatted'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        final selected = await PickerHelpers.showSafeTimePicker(
                          context: context,
                          initialTime: _time,
                        );
                        if (selected != null) {
                          setState(() => _time = selected);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MetricType>(
                initialValue: _metricType,
                decoration: InputDecoration(
                  labelText: l10n.reminderMetric,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.tune_outlined),
                ),
                items: MetricType.values.map((metric) {
                  return DropdownMenuItem(
                    value: metric,
                    child: Text(_metricTitle(metric, l10n)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _metricType = val);
                  }
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.reminderOneTime),
                subtitle: Text(l10n.reminderOneTimeSubtitle),
                value: _isOneTime,
                onChanged: (val) {
                  setState(() => _isOneTime = val);
                },
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _onSave, child: Text(l10n.save)),
            ],
          ),
        ),
      ),
    );
  }
}
