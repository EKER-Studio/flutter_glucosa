import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums/metric_type.dart';
import '../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/presentation/utils/picker_helpers.dart';
import '../../../../core/presentation/widgets/app_empty_view.dart';
import '../../../../core/presentation/widgets/app_error_view.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/app_top_bar.dart';
import '../../../../core/presentation/widgets/clamped_layout.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_list_notifier.dart';
import '../widgets/reminder_card.dart';

/// Screen allowing users to view, configure, toggle, and delete measurement reminders.
class RemindersScreen extends ConsumerWidget {
  /// Creates a [RemindersScreen].
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final remindersAsync = ref.watch(reminderListProvider);

    return Scaffold(
      appBar: AppTopBar(title: l10n.reminders),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditReminderDialog(context, ref),
        icon: const Icon(Icons.add_alarm_outlined),
        label: Text(l10n.addReminder),
      ),
      body: ClampedLayout(
        child: remindersAsync.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (_, _) => Center(
            child: AppErrorView(
              message: l10n.genericError,
              onRetry: () => ref.invalidate(reminderListProvider),
            ),
          ),
          data: (reminders) {
            if (reminders.isEmpty) {
              return Center(
                child: AppEmptyView(
                  icon: Icons.notifications_none_outlined,
                  title: l10n.noRemindersTitle,
                  description: l10n.noRemindersSubtitle,
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return Dismissible(
                  key: ValueKey(reminder.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.onError,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: Text(l10n.deleteReminder),
                            content: Text(l10n.deleteReminderConfirm),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(false),
                                child: Text(l10n.cancel),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    dialogCtx,
                                  ).colorScheme.error,
                                  foregroundColor: Theme.of(
                                    dialogCtx,
                                  ).colorScheme.onError,
                                ),
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(true),
                                child: Text(l10n.deleteReminder),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    await ref
                        .read(reminderListProvider.notifier)
                        .deleteReminder(reminder.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.reminderDeletedSuccess),
                          action: SnackBarAction(
                            label: l10n.undo,
                            onPressed: () {
                              ref
                                  .read(reminderListProvider.notifier)
                                  .addReminder(reminder);
                            },
                          ),
                        ),
                      );
                    }
                  },
                  child: ReminderCard(
                    reminder: reminder,
                    onToggle: (active) async {
                      final (success, failure) = await ref
                          .read(reminderListProvider.notifier)
                          .toggleReminder(reminder.id, active);
                      if (!success && context.mounted) {
                        AppSnackBar.show(
                          context,
                          message: failure != null
                              ? failure.toUserMessage(l10n)
                              : l10n.failedToUpdateReminder,
                          type: SnackBarType.error,
                        );
                      }
                    },
                    onTap: () => _showAddEditReminderDialog(
                      context,
                      ref,
                      existing: reminder,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddEditReminderDialog(
    BuildContext context,
    WidgetRef ref, {
    Reminder? existing,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = existing != null;

    var label = existing?.label ?? '';
    var metricType = existing?.metricType ?? MetricType.glucose;
    var time = TimeOfDay(
      hour: existing?.hourOfDay ?? 8,
      minute: existing?.minute ?? 0,
    );
    var isOneTime = existing?.isOneTime ?? false;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final timeFormatted = time.format(context);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEditing ? (l10n.editReminder) : l10n.addReminder,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: label,
                        autofocus: !isEditing,
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
                        onSaved: (val) => label = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.access_time_outlined),
                              label: Text(
                                '${l10n.reminderTime}: $timeFormatted',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              onPressed: () async {
                                final selected =
                                    await PickerHelpers.showSafeTimePicker(
                                      context: context,
                                      initialTime: time,
                                    );
                                if (selected != null) {
                                  setSheetState(() => time = selected);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<MetricType>(
                        initialValue: metricType,
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
                            setSheetState(() => metricType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.reminderOneTime),
                        subtitle: Text(l10n.reminderOneTimeSubtitle),
                        value: isOneTime,
                        onChanged: (val) {
                          setSheetState(() => isOneTime = val);
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () async {
                          if (formKey.currentState?.validate() ?? false) {
                            formKey.currentState?.save();
                            Navigator.of(context).pop();

                            final reminder = Reminder(
                              id: existing?.id ?? 0,
                              label: label,
                              metricType: metricType,
                              hourOfDay: time.hour,
                              minute: time.minute,
                              isActive: existing?.isActive ?? true,
                              isOneTime: isOneTime,
                            );

                            final (success, failure) = isEditing
                                ? await ref
                                      .read(reminderListProvider.notifier)
                                      .updateReminder(reminder)
                                : await ref
                                      .read(reminderListProvider.notifier)
                                      .addReminder(reminder);

                            if (context.mounted) {
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
                        },
                        child: Text(l10n.save),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
}
