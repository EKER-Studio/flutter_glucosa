import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/blood_pressure/presentation/screens/add_edit_blood_pressure_reading_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/cholesterol/presentation/screens/add_edit_cholesterol_reading_screen.dart';
import '../../features/export/presentation/screens/export_screen.dart';
import '../../features/glucose/presentation/screens/add_edit_glucose_reading_screen.dart';
import '../../features/glucose/presentation/screens/ble_glucose_sync_screen.dart';
import '../../features/hba1c/presentation/screens/add_edit_hba1c_reading_screen.dart';
import '../../features/hba1c/presentation/screens/hba1c_calculator_screen.dart';
import '../../features/ketones/presentation/screens/add_edit_ketone_reading_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/weight/presentation/screens/add_edit_weight_reading_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/overview/presentation/screens/overview_screen.dart';
import '../../features/settings/presentation/screens/licenses_screen.dart';
import '../../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/providers/user_profile_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../presentation/navigation/adaptive_navigation_scaffold.dart';
import '../presentation/screens/startup_error_screen.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

/// Configures the application [GoRouter] instance with declarative routes and error handling.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Rebuilds the router when the profile changes so the onboarding
  // redirect guard below always evaluates the latest completion flag.
  final profileAsync = ref.watch(userProfileProvider);
  final profile = profileAsync.value;
  return GoRouter(
    initialLocation: AppRoute.overview.path,
    debugLogDiagnostics: kDebugMode,
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.matchedLocation;
      final isOnboardingRoute = location == AppRoute.onboarding.path;
      final isStartupErrorRoute = location == AppRoute.startupError.path;
      if (profileAsync.hasError) {
        return isStartupErrorRoute ? null : AppRoute.startupError.path;
      }
      if (profile == null) return null;
      if (isStartupErrorRoute) return AppRoute.overview.path;
      if (!profile.isOnboardingCompleted && !isOnboardingRoute) {
        return AppRoute.onboarding.path;
      }
      if (profile.isOnboardingCompleted && isOnboardingRoute) {
        return AppRoute.overview.path;
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              final l10n = AppLocalizations.of(context)!;
              return AdaptiveNavigationScaffold(
                body: navigationShell,
                currentIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
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
            },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.overview.path,
                name: AppRoute.overview.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const OverviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.calendar.path,
                name: AppRoute.calendar.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.history.path,
                name: AppRoute.history.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.settings.path,
                name: AppRoute.settings.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: AppRoute.licenses.path,
                    name: AppRoute.licenses.name,
                    builder: (BuildContext context, GoRouterState state) =>
                        const LicensesScreen(),
                  ),
                  GoRoute(
                    path: AppRoute.privacyPolicy.path,
                    name: AppRoute.privacyPolicy.name,
                    builder: (BuildContext context, GoRouterState state) =>
                        const PrivacyPolicyScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.addGlucose.path,
        name: AppRoute.addGlucose.name,
        builder: (BuildContext context, GoRouterState state) =>
            const AddEditGlucoseReadingScreen(),
      ),
      GoRoute(
        path: AppRoute.editGlucose.path,
        name: AppRoute.editGlucose.name,
        builder: (BuildContext context, GoRouterState state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '');
          return AddEditGlucoseReadingScreen(readingId: id);
        },
      ),
      GoRoute(
        path: AppRoute.bleGlucoseSync.path,
        name: AppRoute.bleGlucoseSync.name,
        builder: (BuildContext context, GoRouterState state) =>
            const BleGlucoseSyncScreen(),
      ),
      GoRoute(
        path: AppRoute.addHba1c.path,
        name: AppRoute.addHba1c.name,
        builder: (BuildContext context, GoRouterState state) =>
            const AddEditHbA1cReadingScreen(),
      ),
      GoRoute(
        path: AppRoute.editHba1c.path,
        name: AppRoute.editHba1c.name,
        builder: (BuildContext context, GoRouterState state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '');
          return AddEditHbA1cReadingScreen(readingId: id);
        },
      ),
      GoRoute(
        path: AppRoute.addBloodPressure.path,
        name: AppRoute.addBloodPressure.name,
        builder: (BuildContext context, GoRouterState state) =>
            const AddEditBloodPressureReadingScreen(),
      ),
      GoRoute(
        path: AppRoute.editBloodPressure.path,
        name: AppRoute.editBloodPressure.name,
        builder: (BuildContext context, GoRouterState state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '');
          return AddEditBloodPressureReadingScreen(readingId: id);
        },
      ),
      GoRoute(
        path: AppRoute.addKetones.path,
        name: AppRoute.addKetones.name,
        builder: (BuildContext context, GoRouterState state) =>
            const AddEditKetoneReadingScreen(),
      ),
      GoRoute(
        path: AppRoute.editKetones.path,
        name: AppRoute.editKetones.name,
        builder: (BuildContext context, GoRouterState state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '');
          return AddEditKetoneReadingScreen(readingId: id);
        },
      ),
      GoRoute(
        path: AppRoute.addCholesterol.path,
        name: AppRoute.addCholesterol.name,
        builder: (BuildContext context, GoRouterState state) =>
            const AddEditCholesterolReadingScreen(),
      ),
      GoRoute(
        path: AppRoute.editCholesterol.path,
        name: AppRoute.editCholesterol.name,
        builder: (BuildContext context, GoRouterState state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '');
          return AddEditCholesterolReadingScreen(readingId: id);
        },
      ),
      GoRoute(
        path: AppRoute.addWeight.path,
        name: AppRoute.addWeight.name,
        builder: (BuildContext context, GoRouterState state) =>
            const AddEditWeightReadingScreen(),
      ),
      GoRoute(
        path: AppRoute.editWeight.path,
        name: AppRoute.editWeight.name,
        builder: (BuildContext context, GoRouterState state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '');
          return AddEditWeightReadingScreen(readingId: id);
        },
      ),
      GoRoute(
        path: AppRoute.onboarding.path,
        name: AppRoute.onboarding.name,
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoute.reminders.path,
        name: AppRoute.reminders.name,
        builder: (BuildContext context, GoRouterState state) =>
            const RemindersScreen(),
      ),
      GoRoute(
        path: AppRoute.export.path,
        name: AppRoute.export.name,
        builder: (BuildContext context, GoRouterState state) =>
            const ExportScreen(),
      ),
      GoRoute(
        path: AppRoute.hba1cCalculator.path,
        name: AppRoute.hba1cCalculator.name,
        builder: (BuildContext context, GoRouterState state) =>
            const HbA1cCalculatorScreen(),
      ),
      GoRoute(
        path: AppRoute.startupError.path,
        name: AppRoute.startupError.name,
        builder: (BuildContext context, GoRouterState state) =>
            const StartupErrorScreen(),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        body: Center(child: Text(l10n.pageNotFound(state.uri.toString()))),
      );
    },
  );
}
