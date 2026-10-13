import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/add_reading_bottom_sheet.dart';
import '../../../../core/presentation/widgets/app_error_view.dart';
import '../../../../core/presentation/widgets/app_top_bar.dart';
import '../../../../core/presentation/widgets/clamped_layout.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../glucose/presentation/providers/estimated_hba1c_provider.dart';
import '../../../glucose/presentation/providers/glucose_reading_list_notifier.dart';
import '../../../glucose/presentation/providers/latest_glucose_reading_provider.dart';
import '../../../glucose/presentation/widgets/glucose_reading_card.dart';
import '../../../settings/domain/entities/user_profile.dart';
import '../../../settings/presentation/providers/user_profile_notifier.dart';
import '../../../statistics/presentation/utils/summary_share_coordinator.dart';
import '../../../statistics/presentation/widgets/sections/habits_activity_card.dart';
import '../../../statistics/presentation/widgets/sections/milestones_card.dart';
import '../../../statistics/presentation/widgets/sections/period_comparison_card.dart';
import '../providers/overview_insights_provider.dart';
import '../widgets/daily_tip_card.dart';
import '../widgets/estimated_hba1c_card.dart';
import '../widgets/metric_trend_card.dart';
import '../widgets/overview_empty_reading_card.dart';
import '../widgets/overview_target_range_card.dart';
import '../widgets/today_shimmer_skeleton.dart';
import '../widgets/widget_promo_card.dart';

/// Main dashboard overview screen displaying latest readings, health summaries, and quick actions.
class OverviewScreen extends ConsumerWidget {
  /// Creates the overview dashboard screen.
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final latestReadingAsync = ref.watch(latestGlucoseReadingProvider);
    final readingsAsync = ref.watch(glucoseReadingListProvider);
    final estimatedHbA1cAsync = ref.watch(estimatedHbA1cProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: l10n.navOverview,
        actions: [
          if (readingsAsync.value?.isNotEmpty ?? false)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: l10n.shareDoctorSummaryTooltip,
              onPressed: () {
                final readings = readingsAsync.value;
                if (readings == null || readings.isEmpty) return;
                final profile = profileAsync.value ?? const UserProfile();
                SummaryShareCoordinator.shareDoctorSummary(
                  context,
                  readings: readings,
                  profile: profile,
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addReading,
        onPressed: () => showAddReadingBottomSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: ClampedLayout(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(latestGlucoseReadingProvider);
            ref.invalidate(glucoseReadingListProvider);
            ref.invalidate(estimatedHbA1cProvider);
            ref.invalidate(userProfileProvider);
            ref.invalidate(overviewInsightsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.latestReading,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                latestReadingAsync.when(
                  data: (reading) {
                    if (reading == null) {
                      return const OverviewEmptyReadingCard();
                    }
                    return GlucoseReadingCard(
                      reading: reading,
                      onTap: () => context.pushNamed(
                        AppRoute.editGlucose.name,
                        pathParameters: {'id': '${reading.id}'},
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: TodayShimmerSkeleton(),
                  ),
                  error: (_, _) => AppErrorView(
                    message: l10n.genericError,
                    onRetry: () {
                      ref.invalidate(latestGlucoseReadingProvider);
                      ref.invalidate(glucoseReadingListProvider);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                estimatedHbA1cAsync.when(
                  data: (a1c) {
                    if (a1c == null) return const SizedBox.shrink();
                    return EstimatedHbA1cCard(estimatedHbA1c: a1c);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                Text(
                  l10n.chartTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                const MetricTrendCard(),
                const SizedBox(height: 20),

                Text(
                  l10n.targetRange,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                OverviewTargetRangeCard(profile: profileAsync.value),

                readingsAsync.when(
                  data: (readings) {
                    if (readings.isEmpty) return const SizedBox.shrink();
                    final profile = profileAsync.value ?? const UserProfile();
                    final insightsAsync = ref.watch(overviewInsightsProvider);

                    return insightsAsync.when(
                      data: (insights) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          PeriodComparisonCard(
                            readings: readings,
                            unit: profile.preferredGlucoseUnit,
                            targetRange: profile.targetRange,
                          ),
                          if (insights != null) ...[
                            const SizedBox(height: 20),
                            HabitsActivityCard(
                              streak: insights.streak,
                              bestStreak: insights.bestStreak,
                              compliancePct: insights.compliancePct,
                            ),
                            const SizedBox(height: 20),
                            MilestonesCard(milestones: insights.milestones),
                          ],
                          const SizedBox(height: 20),
                          const WidgetPromoCard(),
                        ],
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),
                const DailyTipCard(),
                // Clearance for the end-float FAB so trailing content
                // (e.g. Period Comparison) is never obscured.
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
