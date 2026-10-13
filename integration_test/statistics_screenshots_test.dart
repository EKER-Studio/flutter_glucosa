@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

import 'package:flutter_glucosa/core/presentation/navigation/adaptive_navigation_scaffold.dart';
import 'package:flutter_glucosa/features/overview/presentation/screens/overview_screen.dart';
import 'package:flutter_glucosa/features/statistics/domain/services/milestone_calculator.dart';
import 'package:flutter_glucosa/features/statistics/presentation/utils/milestone_icon_resolver.dart';
import 'package:flutter_glucosa/features/statistics/presentation/utils/milestone_localizer.dart';
import 'package:flutter_glucosa/features/statistics/presentation/widgets/components/milestones_gallery_sheet.dart';
import 'package:flutter_glucosa/features/statistics/presentation/widgets/sections/period_comparison_card.dart';
import 'package:flutter_glucosa/l10n/app_localizations.dart';
import 'helpers/screenshot_test_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final effectiveLocales = getEffectiveLocales();
  final prefix = getScreenshotPrefix();

  late ScreenshotMockData mockData;

  setUpAll(() async {
    mockData = await initScreenshotEnvironment(binding);
  });

  tearDownAll(() {
    mockData.dispose();
  });

  Widget buildAdaptiveScaffold(BuildContext context, Widget body, int index) {
    final l10n = AppLocalizations.of(context)!;
    return AdaptiveNavigationScaffold(
      body: body,
      currentIndex: index,
      onDestinationSelected: (_) {},
      destinations: [
        AdaptiveNavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: l10n.navOverview,
        ),
        AdaptiveNavigationDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month),
          label: l10n.tabCalendar,
        ),
        AdaptiveNavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(Icons.history),
          label: l10n.navHistory,
        ),
        AdaptiveNavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.navSettings,
        ),
      ],
    );
  }

  group('04_statistics Screenshot Generator', () {
    for (final localeCode in effectiveLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final locale = Locale(localeCode);

        // 04_statistics / 01_overview
        testWidgets(
          'Capture 04_statistics/01_overview [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildScreenshotAppWrapper(
                locale: locale,
                isDark: isDark,
                mockData: mockData,
                showNotificationIcon: true,
                child: Builder(
                  builder: (context) =>
                      buildAdaptiveScaffold(context, const OverviewScreen(), 0),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            // Scroll down so habits and milestone section are prominent.
            // NOTE: nested chip rows are scrollable too — the page scroll
            // is the outermost match.
            final scrollable = find.byType(Scrollable).first;
            if (scrollable.evaluate().isNotEmpty) {
              tester.state<ScrollableState>(scrollable).position.jumpTo(350);
              await tester.pumpAndSettle();
            }

            await binding.takeScreenshot(
              '$prefix$localeCode/04_statistics/01_overview_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 04_statistics / 02_achievements_gallery
        testWidgets(
          'Capture 04_statistics/02_achievements_gallery [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final evaluatedMilestones = MilestoneCalculator.evaluateAll(
              readings: generate90MockGlucoseReadings(localeCode),
            );

            await tester.pumpWidget(
              buildScreenshotAppWrapper(
                locale: locale,
                isDark: isDark,
                mockData: mockData,
                showNotificationIcon: true,
                child: Builder(
                  builder: (context) => Stack(
                    children: [
                      buildAdaptiveScaffold(context, const OverviewScreen(), 0),
                      const ModalBarrier(
                        dismissible: false,
                        color: Colors.black54,
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ScreenshotBottomSheetContainer(
                          child: MilestonesGallerySheet(
                            milestones: evaluatedMilestones,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$prefix$localeCode/04_statistics/02_achievements_gallery_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 04_statistics / 03_achievement_detail
        testWidgets(
          'Capture 04_statistics/03_achievement_detail [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final evaluatedMilestones = MilestoneCalculator.evaluateAll(
              readings: generate90MockGlucoseReadings(localeCode),
            );

            final milestone = evaluatedMilestones.firstWhere(
              (m) => m.isUnlocked && m.unlockedDate != null,
              orElse: () => evaluatedMilestones.first,
            );

            await tester.pumpWidget(
              buildScreenshotAppWrapper(
                locale: locale,
                isDark: isDark,
                mockData: mockData,
                showNotificationIcon: true,
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    final cs = Theme.of(context).colorScheme;
                    final title = milestone.type.localizedTitle(l10n);
                    final description = milestone.type.localizedDescription(
                      l10n,
                    );

                    return Stack(
                      children: [
                        buildAdaptiveScaffold(
                          context,
                          const OverviewScreen(),
                          0,
                        ),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: ScreenshotBottomSheetContainer(
                            child: MilestonesGallerySheet(
                              milestones: evaluatedMilestones,
                            ),
                          ),
                        ),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Center(
                          child: AlertDialog(
                            scrollable: true,
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            icon: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: milestone.isUnlocked
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                MilestoneIconResolver.iconForType(
                                  milestone.type,
                                ),
                                size: 26,
                                color: milestone.isUnlocked
                                    ? cs.primary
                                    : cs.onSurfaceVariant.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                            ),
                            title: Text(title, textAlign: TextAlign.center),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  description,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                                const SizedBox(height: 16),
                                if (milestone.isUnlocked &&
                                    milestone.unlockedDate != null) ...[
                                  Text(
                                    DateFormat.yMMMMd(
                                      l10n.localeName,
                                    ).format(milestone.unlockedDate!),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      height: 6,
                                      width: double.infinity,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {},
                                child: Text(l10n.close),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$prefix$localeCode/04_statistics/03_achievement_detail_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 04_statistics / 04_period_comparison_scrolled
        testWidgets(
          'Capture 04_statistics/04_period_comparison_scrolled [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildScreenshotAppWrapper(
                locale: locale,
                isDark: isDark,
                mockData: mockData,
                showNotificationIcon: true,
                child: Builder(
                  builder: (context) =>
                      buildAdaptiveScaffold(context, const OverviewScreen(), 0),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            final scrollable = find.byType(Scrollable).first;
            expect(scrollable, findsOneWidget);
            tester.state<ScrollableState>(scrollable).position.jumpTo(1150);
            await tester.pumpAndSettle();

            final periodComparison = find.byType(PeriodComparisonCard);
            expect(periodComparison, findsOneWidget);

            await binding.takeScreenshot(
              '$prefix$localeCode/04_statistics/04_period_comparison_scrolled_$themeLabel',
            );
          },
          tags: 'screenshot',
        );
      }
    }
  });
}
