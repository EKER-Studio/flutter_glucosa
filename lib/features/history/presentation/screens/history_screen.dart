import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums/metric_type.dart';
import '../../../../core/presentation/widgets/add_reading_bottom_sheet.dart';
import '../../../../core/presentation/widgets/app_empty_view.dart';
import '../../../../core/presentation/widgets/app_error_view.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/app_top_bar.dart';
import '../../../../core/presentation/widgets/clamped_layout.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blood_pressure/presentation/providers/blood_pressure_reading_list_notifier.dart';
import '../../../cholesterol/presentation/providers/cholesterol_reading_list_notifier.dart';
import '../../../glucose/presentation/providers/glucose_reading_list_notifier.dart';
import '../../../hba1c/presentation/providers/hba1c_reading_list_notifier.dart';
import '../../../ketones/presentation/providers/ketone_reading_list_notifier.dart';
import '../../../weight/presentation/providers/weight_reading_list_notifier.dart';
import '../utils/history_entry_action_handler.dart';
import '../utils/history_entry_merger.dart';
import '../widgets/history_card_builder.dart';
import '../widgets/history_filter_chips.dart';

/// Screen presenting chronological history of all logged health measurements with metric filtering.
class HistoryScreen extends ConsumerStatefulWidget {
  /// Creates the history log screen.
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  /// Currently selected metric filter, or `null` to show all metrics.
  MetricType? _filter;

  void _refreshAll() {
    ref.invalidate(glucoseReadingListProvider);
    ref.invalidate(hbA1cReadingListProvider);
    ref.invalidate(bloodPressureReadingListProvider);
    ref.invalidate(ketoneReadingListProvider);
    ref.invalidate(cholesterolReadingListProvider);
    ref.invalidate(weightReadingListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final glucoseAsync = ref.watch(glucoseReadingListProvider);
    final hba1cAsync = ref.watch(hbA1cReadingListProvider);
    final bloodPressureAsync = ref.watch(bloodPressureReadingListProvider);
    final ketonesAsync = ref.watch(ketoneReadingListProvider);
    final cholesterolAsync = ref.watch(cholesterolReadingListProvider);
    final weightAsync = ref.watch(weightReadingListProvider);

    final states = [
      glucoseAsync,
      hba1cAsync,
      bloodPressureAsync,
      ketonesAsync,
      cholesterolAsync,
      weightAsync,
    ];

    return Scaffold(
      appBar: AppTopBar(title: l10n.navHistory),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addReading,
        onPressed: () => showAddReadingBottomSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: ClampedLayout(
        child: Column(
          children: [
            HistoryFilterChips(
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (states.any((s) => s.hasError)) {
                    return Center(
                      child: AppErrorView(
                        message: l10n.genericError,
                        onRetry: _refreshAll,
                      ),
                    );
                  }
                  if (states.any((s) => s.isLoading)) {
                    return const Center(child: AppLoadingIndicator());
                  }

                  final entries = HistoryEntryMerger.merge(
                    glucose: glucoseAsync.value ?? const [],
                    hba1c: hba1cAsync.value ?? const [],
                    bloodPressure: bloodPressureAsync.value ?? const [],
                    ketones: ketonesAsync.value ?? const [],
                    cholesterol: cholesterolAsync.value ?? const [],
                    weight: weightAsync.value ?? const [],
                  );

                  final visible = HistoryEntryMerger.filterAndWindow(
                    entries: entries,
                    filter: _filter,
                  );

                  if (visible.isEmpty) {
                    return AppEmptyView(
                      title: l10n.noReadingsYet,
                      icon: Icons.water_drop_outlined,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _refreshAll(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = visible[index];
                        final id = HistoryEntryActionHandler.readingId(
                          entry.reading,
                        );
                        final theme = Theme.of(context);
                        return Dismissible(
                          key: ValueKey('${entry.type.name}_$id'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) =>
                              HistoryEntryActionHandler.confirmDelete(
                                context,
                                entry.type,
                              ),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.onError,
                            ),
                          ),
                          onDismissed: (_) async {
                            await HistoryEntryActionHandler.deleteEntry(
                              ref,
                              entry,
                            );
                            if (context.mounted) {
                              final l10n = AppLocalizations.of(context)!;
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    HistoryEntryActionHandler.deleteSuccessMessage(
                                      entry.type,
                                      l10n,
                                    ),
                                  ),
                                  action: SnackBarAction(
                                    label: l10n.undo,
                                    onPressed: () =>
                                        HistoryEntryActionHandler.restoreEntry(
                                          ref,
                                          entry,
                                        ),
                                  ),
                                ),
                              );
                            }
                          },
                          child: HistoryCardBuilder.build(context, entry),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
