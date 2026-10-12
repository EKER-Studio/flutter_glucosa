import 'package:flutter/material.dart';
import 'package:flutter_glucosa/core/router/app_router.dart';
import 'package:flutter_glucosa/core/router/app_routes.dart';
import 'package:flutter_glucosa/features/export/data/providers/export_service_provider.dart';
import 'package:flutter_glucosa/features/export/presentation/screens/export_screen.dart';
import 'package:flutter_glucosa/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:flutter_glucosa/features/glucose/data/providers/glucose_reading_repository_provider.dart';
import 'package:flutter_glucosa/features/glucose/presentation/screens/add_edit_glucose_reading_screen.dart';
import 'package:flutter_glucosa/features/glucose/presentation/screens/ble_glucose_sync_screen.dart';
import 'package:flutter_glucosa/features/hba1c/data/providers/hba1c_reading_repository_provider.dart';
import 'package:flutter_glucosa/features/hba1c/presentation/screens/hba1c_calculator_screen.dart';
import 'package:flutter_glucosa/features/history/presentation/screens/history_screen.dart';
import 'package:flutter_glucosa/features/overview/presentation/screens/overview_screen.dart';
import 'package:flutter_glucosa/features/reminders/data/providers/reminder_repository_provider.dart';
import 'package:flutter_glucosa/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:flutter_glucosa/features/settings/data/providers/user_profile_repository_provider.dart';
import 'package:flutter_glucosa/features/settings/domain/entities/user_profile.dart';
import 'package:flutter_glucosa/features/settings/presentation/screens/licenses_screen.dart';
import 'package:flutter_glucosa/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:flutter_glucosa/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_glucosa/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_glucosa/features/glucose/data/providers/ble_glucose_sync_providers.dart';
import '../../helpers/fake_ble_glucose_sync_repository.dart';
import '../../helpers/fake_export_service.dart';
import '../../helpers/fake_glucose_reading_repository.dart';
import '../../helpers/fake_hba1c_reading_repository.dart';
import '../../helpers/fake_reminder_repository.dart';
import '../../helpers/fake_user_profile_repository.dart';

void main() {
  late FakeUserProfileRepository fakeUserProfileRepository;
  late FakeGlucoseReadingRepository fakeGlucoseReadingRepository;
  late FakeHbA1cReadingRepository fakeHbA1cReadingRepository;
  late FakeReminderRepository fakeReminderRepository;
  late FakeExportService fakeExportService;
  late FakeBleGlucoseSyncRepository fakeBleGlucoseSyncRepository;

  setUp(() {
    // Seed a completed profile so the onboarding guard lets tests through
    // to the requested routes; guard behavior itself is tested separately.
    fakeUserProfileRepository = FakeUserProfileRepository(
      initialProfile: UserProfile.defaults().copyWith(
        isOnboardingCompleted: true,
      ),
    );
    fakeGlucoseReadingRepository = FakeGlucoseReadingRepository();
    fakeHbA1cReadingRepository = FakeHbA1cReadingRepository();
    fakeReminderRepository = FakeReminderRepository();
    fakeExportService = FakeExportService();
    fakeBleGlucoseSyncRepository = FakeBleGlucoseSyncRepository();
  });

  tearDown(() {
    fakeUserProfileRepository.dispose();
    fakeGlucoseReadingRepository.dispose();
    fakeHbA1cReadingRepository.dispose();
    fakeReminderRepository.dispose();
    fakeBleGlucoseSyncRepository.dispose();
  });

  Widget createTestApp({String? initialLocation}) {
    return ProviderScope(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(
          fakeUserProfileRepository,
        ),
        glucoseReadingRepositoryProvider.overrideWithValue(
          fakeGlucoseReadingRepository,
        ),
        hbA1cReadingRepositoryProvider.overrideWithValue(
          fakeHbA1cReadingRepository,
        ),
        reminderRepositoryProvider.overrideWithValue(fakeReminderRepository),
        exportServiceProvider.overrideWithValue(fakeExportService),
        bleGlucoseSyncRepositoryProvider.overrideWithValue(
          fakeBleGlucoseSyncRepository,
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);
          if (initialLocation != null) {
            router.go(initialLocation);
          }
          return MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }

  group('AppRouter Tests', () {
    test('AppRoute enum definitions have correct paths and names', () {
      expect(AppRoute.overview.path, '/');
      expect(AppRoute.overview.name, 'overview');
      expect(AppRoute.calendar.path, '/calendar');
      expect(AppRoute.calendar.name, 'calendar');
      expect(AppRoute.history.path, '/history');
      expect(AppRoute.history.name, 'history');
      expect(AppRoute.settings.path, '/settings');
      expect(AppRoute.settings.name, 'settings');
      expect(AppRoute.licenses.path, 'licenses');
      expect(AppRoute.licenses.name, 'licenses');
      expect(AppRoute.privacyPolicy.path, 'privacy-policy');
      expect(AppRoute.privacyPolicy.name, 'privacy_policy');
      expect(AppRoute.addGlucose.path, '/glucose/add');
      expect(AppRoute.addGlucose.name, 'add_glucose');
      expect(AppRoute.editGlucose.path, '/glucose/edit/:id');
      expect(AppRoute.editGlucose.name, 'edit_glucose');
      expect(AppRoute.addBloodPressure.path, '/blood-pressure/add');
      expect(AppRoute.addBloodPressure.name, 'add_blood_pressure');
      expect(AppRoute.editBloodPressure.path, '/blood-pressure/edit/:id');
      expect(AppRoute.editBloodPressure.name, 'edit_blood_pressure');
      expect(AppRoute.addKetones.path, '/ketones/add');
      expect(AppRoute.addKetones.name, 'add_ketones');
      expect(AppRoute.editKetones.path, '/ketones/edit/:id');
      expect(AppRoute.editKetones.name, 'edit_ketones');
      expect(AppRoute.addCholesterol.path, '/cholesterol/add');
      expect(AppRoute.addCholesterol.name, 'add_cholesterol');
      expect(AppRoute.editCholesterol.path, '/cholesterol/edit/:id');
      expect(AppRoute.editCholesterol.name, 'edit_cholesterol');
      expect(AppRoute.addWeight.path, '/weight/add');
      expect(AppRoute.addWeight.name, 'add_weight');
      expect(AppRoute.editWeight.path, '/weight/edit/:id');
      expect(AppRoute.editWeight.name, 'edit_weight');
      expect(AppRoute.export.path, '/export');
      expect(AppRoute.export.name, 'export');
      expect(AppRoute.hba1cCalculator.path, '/hba1c-calculator');
      expect(AppRoute.hba1cCalculator.name, 'hba1c_calculator');
    });

    testWidgets('Renders OverviewScreen on initial "/" route', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('Navigates to CalendarScreen on "/calendar" route', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/calendar'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('Navigates to HistoryScreen on "/history" route', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/history'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);
    });

    testWidgets('Navigates to SettingsScreen on "/settings" route', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Navigates to LicensesScreen on "/settings/licenses" route', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(initialLocation: '/settings/licenses'),
      );
      await tester.pump();

      expect(find.byType(LicensesScreen), findsOneWidget);
    });

    testWidgets(
      'Navigates to PrivacyPolicyScreen on "/settings/privacy-policy" route',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(initialLocation: '/settings/privacy-policy'),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      },
    );

    testWidgets('Navigates to AddEditGlucoseReadingScreen on "/glucose/add"', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/glucose/add'));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditGlucoseReadingScreen), findsOneWidget);
      expect(find.text('Add Glucose Reading'), findsOneWidget);
    });

    testWidgets(
      'Navigates to AddEditGlucoseReadingScreen on "/glucose/edit/1"',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(initialLocation: '/glucose/edit/1'),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AddEditGlucoseReadingScreen), findsOneWidget);
      },
    );

    testWidgets('Navigates to BleGlucoseSyncScreen on "/glucose/sync"', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/glucose/sync'));
      await tester.pumpAndSettle();

      expect(find.byType(BleGlucoseSyncScreen), findsOneWidget);
    });

    testWidgets(
      'Tapping Bluetooth action in AddEditGlucoseReadingScreen navigates to BleGlucoseSyncScreen',
      (tester) async {
        await tester.pumpWidget(createTestApp(initialLocation: '/glucose/add'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bluetooth), findsOneWidget);
        await tester.tap(find.byIcon(Icons.bluetooth));
        await tester.pumpAndSettle();

        expect(find.byType(BleGlucoseSyncScreen), findsOneWidget);
      },
    );

    testWidgets('Navigates to AddEditHbA1cReadingScreen on "/hba1c/add"', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/hba1c/add'));
      await tester.pumpAndSettle();

      expect(find.text('Log HbA1c'), findsOneWidget);
    });

    testWidgets('Navigates to AddEditHbA1cReadingScreen on "/hba1c/edit/1"', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/hba1c/edit/1'));
      await tester.pumpAndSettle();

      expect(find.text('Edit HbA1c'), findsOneWidget);
    });

    testWidgets(
      'Navigates to AddEditBloodPressureReadingScreen on "/blood-pressure/add"',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(initialLocation: '/blood-pressure/add'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Blood Pressure'), findsOneWidget);
      },
    );

    testWidgets(
      'Navigates to AddEditBloodPressureReadingScreen on "/blood-pressure/edit/1"',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(initialLocation: '/blood-pressure/edit/1'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit Blood Pressure'), findsOneWidget);
      },
    );

    testWidgets('Navigates to AddEditKetoneReadingScreen on "/ketones/add"', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/ketones/add'));
      await tester.pumpAndSettle();

      expect(find.text('Log Ketones'), findsOneWidget);
    });

    testWidgets(
      'Navigates to AddEditKetoneReadingScreen on "/ketones/edit/1"',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(initialLocation: '/ketones/edit/1'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit Ketones'), findsOneWidget);
      },
    );

    testWidgets(
      'Navigates to AddEditCholesterolReadingScreen on "/cholesterol/add"',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(initialLocation: '/cholesterol/add'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Log Cholesterol'), findsOneWidget);
      },
    );

    testWidgets(
      'Navigates to AddEditCholesterolReadingScreen on "/cholesterol/edit/1"',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(initialLocation: '/cholesterol/edit/1'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit Cholesterol'), findsOneWidget);
      },
    );

    testWidgets('Navigates to AddEditWeightReadingScreen on "/weight/add"', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/weight/add'));
      await tester.pumpAndSettle();

      expect(find.text('Log Weight'), findsOneWidget);
    });

    testWidgets('Navigates to AddEditWeightReadingScreen on "/weight/edit/1"', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/weight/edit/1'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Weight'), findsOneWidget);
    });

    testWidgets('Navigates to RemindersScreen on "/reminders"', (tester) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/reminders'));
      await tester.pumpAndSettle();

      expect(find.byType(RemindersScreen), findsOneWidget);
    });

    testWidgets('Navigates to ExportScreen on "/export"', (tester) async {
      await tester.pumpWidget(createTestApp(initialLocation: '/export'));
      await tester.pumpAndSettle();

      expect(find.byType(ExportScreen), findsOneWidget);
    });

    testWidgets('Navigates to HbA1cCalculatorScreen on "/hba1c-calculator"', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(initialLocation: '/hba1c-calculator'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HbA1cCalculatorScreen), findsOneWidget);
    });

    testWidgets('Renders error screen on unknown route', (tester) async {
      await tester.pumpWidget(
        createTestApp(initialLocation: '/unknown-route-404'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Page not found'), findsOneWidget);
    });

    group('Onboarding redirect guard', () {
      testWidgets('redirects to onboarding when profile is incomplete', (
        tester,
      ) async {
        fakeUserProfileRepository.dispose();
        fakeUserProfileRepository = FakeUserProfileRepository();

        await tester.pumpWidget(createTestApp(initialLocation: '/'));
        await tester.pumpAndSettle();

        expect(find.text('Welcome to Glucosa'), findsOneWidget);
      });

      testWidgets('redirects away from onboarding when already completed', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(initialLocation: '/onboarding'));
        await tester.pumpAndSettle();

        expect(find.byType(OverviewScreen), findsOneWidget);
      });
    });
  });
}
