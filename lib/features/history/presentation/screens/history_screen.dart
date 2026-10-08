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
import '../../../blood_pressure/domain/entities/blood_pressure_reading.dart';
import '../../../blood_pressure/presentation/providers/blood_pressure_reading_list_notifier.dart';
import '../../../cholesterol/domain/entities/cholesterol_reading.dart';
import '../../../cholesterol/presentation/providers/cholesterol_reading_list_notifier.dart';
import '../../../glucose/domain/entities/glucose_reading.dart';
import '../../../glucose/presentation/providers/glucose_reading_list_notifier.dart';
import '../../../hba1c/domain/entities/hba1c_reading.dart';
import '../../../hba1c/presentation/providers/hba1c_reading_list_notifier.dart';
import '../../../ketones/domain/entities/ketone_reading.dart';
import '../../../ketones/presentation/providers/ketone_reading_list_notifier.dart';
import '../../../weight/domain/entities/weight_reading.dart';
import '../../../weight/presentation/providers/weight_reading_list_notifier.dart';
import '../models/history_entry.dart';
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
  /// Rolling window rendered by the history list; older records remain in
  /// the database and exports. Repository-level date-range queries
  /// (`getByDateRange`) back this window for targeted fetches.
  static const Duration _historyWindow = Duration(days: 365);

  /// Upper bound on merged in-memory entries to avoid unbounded heap growth.
  static const int _maxVisibleEntries = 1000;

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

                  final entries = _mergeEntries(
                    glucoseAsync.value ?? const [],
                    hba1cAsync.value ?? const [],
                    bloodPressureAsync.value ?? const [],
                    ketonesAsync.value ?? const [],
                    cholesterolAsync.value ?? const [],
                    weightAsync.value ?? const [],
                  );
                  final cutoff = DateTime.now().subtract(_historyWindow);
                  final windowed = entries
                      .where((e) => e.createdAt.isAfter(cutoff))
                      .take(_maxVisibleEntries)
                      .toList();
                  final visible = _filter == null
                      ? windowed
                      : windowed.where((e) => e.type == _filter).toList();

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
                        final id = _readingId(entry.reading);
                        final theme = Theme.of(context);
                        return Dismissible(
                          key: ValueKey('${entry.type.name}_$id'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) =>
                              _confirmDelete(context, entry.type),
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
                            await _deleteEntry(entry);
                            if (context.mounted) {
                              final l10n = AppLocalizations.of(context)!;
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _deleteSuccessMessage(entry.type, l10n),
                                  ),
                                  action: SnackBarAction(
                                    label: l10n.undo,
                                    onPressed: () => _restoreEntry(entry),
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

  /// Merges all metric readings into a single chronological list (newest first).
  List<HistoryEntry> _mergeEntries(
    List<GlucoseReading> glucose,
    List<HbA1cReading> hba1c,
    List<BloodPressureReading> bloodPressure,
    List<KetoneReading> ketones,
    List<CholesterolReading> cholesterol,
    List<WeightReading> weight,
  ) {
    final entries = <HistoryEntry>[
      for (final r in glucose)
        HistoryEntry(
          type: MetricType.glucose,
          createdAt: r.createdAt,
          reading: r,
        ),
      for (final r in hba1c)
        HistoryEntry(
          type: MetricType.hba1c,
          createdAt: r.createdAt,
          reading: r,
        ),
      for (final r in bloodPressure)
        HistoryEntry(
          type: MetricType.bloodPressure,
          createdAt: r.createdAt,
          reading: r,
        ),
      for (final r in ketones)
        HistoryEntry(
          type: MetricType.ketones,
          createdAt: r.createdAt,
          reading: r,
        ),
      for (final r in cholesterol)
        HistoryEntry(
          type: MetricType.cholesterol,
          createdAt: r.createdAt,
          reading: r,
        ),
      for (final r in weight)
        HistoryEntry(
          type: MetricType.weight,
          createdAt: r.createdAt,
          reading: r,
        ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  int _readingId(Object reading) {
    return switch (reading) {
      GlucoseReading r => r.id,
      HbA1cReading r => r.id,
      BloodPressureReading r => r.id,
      KetoneReading r => r.id,
      CholesterolReading r => r.id,
      WeightReading r => r.id,
      _ => 0,
    };
  }

  Future<void> _deleteEntry(HistoryEntry entry) {
    return switch (entry.reading) {
      GlucoseReading r =>
        ref.read(glucoseReadingListProvider.notifier).deleteReading(r.id),
      HbA1cReading r =>
        ref.read(hbA1cReadingListProvider.notifier).deleteReading(r.id),
      BloodPressureReading r =>
        ref.read(bloodPressureReadingListProvider.notifier).deleteReading(r.id),
      KetoneReading r =>
        ref.read(ketoneReadingListProvider.notifier).deleteReading(r.id),
      CholesterolReading r =>
        ref.read(cholesterolReadingListProvider.notifier).deleteReading(r.id),
      WeightReading r =>
        ref.read(weightReadingListProvider.notifier).deleteReading(r.id),
      _ => Future.value(),
    };
  }

  Future<void> _restoreEntry(HistoryEntry entry) {
    return switch (entry.reading) {
      GlucoseReading r =>
        ref.read(glucoseReadingListProvider.notifier).addReading(r),
      HbA1cReading r =>
        ref.read(hbA1cReadingListProvider.notifier).addReading(r),
      BloodPressureReading r =>
        ref.read(bloodPressureReadingListProvider.notifier).addReading(r),
      KetoneReading r =>
        ref.read(ketoneReadingListProvider.notifier).addReading(r),
      CholesterolReading r =>
        ref.read(cholesterolReadingListProvider.notifier).addReading(r),
      WeightReading r =>
        ref.read(weightReadingListProvider.notifier).addReading(r),
      _ => Future.value(),
    };
  }

  String _deleteSuccessMessage(MetricType type, AppLocalizations l10n) {
    return switch (type) {
      MetricType.glucose => l10n.glucoseReadingDeleted,
      MetricType.hba1c => l10n.hba1cDeletedSuccess,
      MetricType.bloodPressure => l10n.bpDeletedSuccess,
      MetricType.ketones => l10n.ketonesDeletedSuccess,
      MetricType.cholesterol => l10n.cholesterolDeletedSuccess,
      MetricType.weight => l10n.weightDeletedSuccess,
    };
  }

  /// Shows the shared delete-confirmation dialog for [type].
  Future<bool> _confirmDelete(BuildContext context, MetricType type) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteReadingConfirmationTitle),
        content: Text(_deleteConfirmMessage(type, l10n)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// Returns the per-metric delete-confirmation message for [type].
  String _deleteConfirmMessage(MetricType type, AppLocalizations l10n) {
    return switch (type) {
      MetricType.glucose => l10n.deleteReadingConfirmationMessage,
      MetricType.hba1c => l10n.deleteHba1cConfirm,
      MetricType.bloodPressure => l10n.deleteBloodPressureConfirm,
      MetricType.ketones => l10n.deleteKetonesConfirm,
      MetricType.cholesterol => l10n.deleteCholesterolConfirm,
      MetricType.weight => l10n.deleteWeightConfirm,
    };
  }
}
