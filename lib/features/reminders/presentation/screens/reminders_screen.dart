import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/presentation/widgets/app_empty_view.dart';
import '../../../../core/presentation/widgets/app_error_view.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/app_top_bar.dart';
import '../../../../core/presentation/widgets/clamped_layout.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/reminder_list_notifier.dart';
import '../widgets/add_edit_reminder_bottom_sheet.dart';
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
        onPressed: () => AddEditReminderBottomSheet.show(context),
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
                    onTap: () => AddEditReminderBottomSheet.show(
                      context,
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
}
