import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums/metric_type.dart';
import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/presentation/widgets/app_error_view.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/clamped_layout.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../glucose/presentation/utils/csv_import_coordinator.dart';
import '../../domain/models/date_range_filter.dart';
import '../providers/export_notifier.dart';
import '../providers/export_state.dart';
import '../widgets/export_csv_import_card.dart';
import '../widgets/export_date_preset_chips.dart';
import '../widgets/export_metrics_selection_card.dart';

/// Screen enabling users to configure and export their health measurement data to CSV.
class ExportScreen extends ConsumerWidget {
  /// Creates an [ExportScreen].
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final exportAsync = ref.watch(exportProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportData)),
      body: ClampedLayout(
        child: exportAsync.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (error, _) => Center(
            child: AppErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(exportProvider),
            ),
          ),
          data: (state) => _ExportContent(state: state),
        ),
      ),
    );
  }
}

class _ExportContent extends ConsumerStatefulWidget {
  final ExportState state;

  const _ExportContent({required this.state});

  @override
  ConsumerState<_ExportContent> createState() => _ExportContentState();
}

class _ExportContentState extends ConsumerState<_ExportContent> {
  ExportDatePreset _activePreset = ExportDatePreset.allTime;
  bool _isImporting = false;

  Future<void> _handleExport(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await ref.read(exportProvider.notifier).exportAndShare();
    if (success && context.mounted) {
      AppSnackBar.show(
        context,
        message: l10n.exportSuccess,
        type: SnackBarType.success,
      );
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isImporting = true);
    try {
      final count = await CsvImportCoordinator.pickAnalyzeConfirm(context, ref);
      if (!context.mounted) return;
      if (count != null) {
        ref.invalidate(exportProvider);
        AppSnackBar.show(
          context,
          message: l10n.csvImportSuccess(count),
          type: SnackBarType.success,
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = widget.state;
    final allSelected =
        state.selectedMetrics.length == MetricType.values.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Text(
          l10n.exportSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),

        ExportDatePresetChips(
          activePreset: _activePreset,
          dateRange: state.dateRange,
          onPresetSelected: (preset, days) {
            setState(() => _activePreset = preset);
            ref.read(exportProvider.notifier).setLastDaysPreset(days);
          },
          onCustomRangeSelected: (picked) {
            setState(() => _activePreset = ExportDatePreset.custom);
            ref
                .read(exportProvider.notifier)
                .setDateRange(
                  DateRangeFilter(start: picked.start, end: picked.end),
                );
          },
        ),
        const SizedBox(height: 24),

        ExportMetricsSelectionCard(
          selectedMetrics: state.selectedMetrics,
          onToggleSelectAll: () {
            ref.read(exportProvider.notifier).setSelectAllMetrics(!allSelected);
          },
          onToggleMetric: (metric) {
            ref.read(exportProvider.notifier).toggleMetric(metric);
          },
        ),
        const SizedBox(height: 20),

        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.summarize_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.exportMatchingRecords(state.matchingRecordCount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (state.error != null) ...[
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      switch (state.error!) {
                        ExportError.emptyMetrics =>
                          l10n.exportNoMetricsSelected,
                        ExportError.exportFailed => l10n.genericError,
                      },
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 28),

        FilledButton.icon(
          onPressed: (state.isExporting || state.selectedMetrics.isEmpty)
              ? null
              : () => _handleExport(context),
          icon: state.isExporting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.share_outlined),
          label: Text(l10n.exportAndShare),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 28),

        ExportCsvImportCard(
          isImporting: _isImporting,
          onImport: () => _handleImport(context),
        ),
      ],
    );
  }
}
