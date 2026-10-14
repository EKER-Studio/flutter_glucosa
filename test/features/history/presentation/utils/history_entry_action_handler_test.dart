import 'package:flutter/material.dart';
import 'package:flutter_glucosa/core/domain/enums/meal_context.dart';
import 'package:flutter_glucosa/core/domain/enums/metric_type.dart';
import 'package:flutter_glucosa/features/blood_pressure/data/providers/blood_pressure_reading_repository_provider.dart';
import 'package:flutter_glucosa/features/blood_pressure/domain/entities/blood_pressure_reading.dart';
import 'package:flutter_glucosa/features/blood_pressure/domain/repositories/blood_pressure_reading_repository.dart';
import 'package:flutter_glucosa/features/cholesterol/data/providers/cholesterol_reading_repository_provider.dart';
import 'package:flutter_glucosa/features/cholesterol/domain/entities/cholesterol_reading.dart';
import 'package:flutter_glucosa/features/cholesterol/domain/repositories/cholesterol_reading_repository.dart';
import 'package:flutter_glucosa/features/glucose/data/providers/glucose_reading_repository_provider.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/glucose_reading.dart';
import 'package:flutter_glucosa/features/glucose/domain/repositories/glucose_reading_repository.dart';
import 'package:flutter_glucosa/features/hba1c/data/providers/hba1c_reading_repository_provider.dart';
import 'package:flutter_glucosa/features/hba1c/domain/entities/hba1c_reading.dart';
import 'package:flutter_glucosa/features/hba1c/domain/repositories/hba1c_reading_repository.dart';
import 'package:flutter_glucosa/features/history/presentation/models/history_entry.dart';
import 'package:flutter_glucosa/features/history/presentation/utils/history_entry_action_handler.dart';
import 'package:flutter_glucosa/features/ketones/data/providers/ketone_reading_repository_provider.dart';
import 'package:flutter_glucosa/features/ketones/domain/entities/ketone_reading.dart';
import 'package:flutter_glucosa/features/ketones/domain/repositories/ketone_reading_repository.dart';
import 'package:flutter_glucosa/features/weight/data/providers/weight_reading_repository_provider.dart';
import 'package:flutter_glucosa/features/weight/domain/entities/weight_reading.dart';
import 'package:flutter_glucosa/features/weight/domain/repositories/weight_reading_repository.dart';
import 'package:flutter_glucosa/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGlucoseReadingRepository extends Mock
    implements GlucoseReadingRepository {}

class MockHbA1cReadingRepository extends Mock
    implements HbA1cReadingRepository {}

class MockBloodPressureReadingRepository extends Mock
    implements BloodPressureReadingRepository {}

class MockKetoneReadingRepository extends Mock
    implements KetoneReadingRepository {}

class MockCholesterolReadingRepository extends Mock
    implements CholesterolReadingRepository {}

class MockWeightReadingRepository extends Mock
    implements WeightReadingRepository {}

void main() {
  final testDate = DateTime(2026, 3, 15, 12, 0);

  final glucose = GlucoseReading(
    id: 101,
    readingMgDl: 110,
    mealContext: MealContext.fasting,
    createdAt: testDate,
  );

  final hba1c = HbA1cReading(
    id: 102,
    readingPercentage: 6.2,
    createdAt: testDate,
  );

  final bp = BloodPressureReading(
    id: 103,
    systolicMmHg: 120,
    diastolicMmHg: 80,
    createdAt: testDate,
  );

  final ketone = KetoneReading(id: 104, readingMmolL: 0.6, createdAt: testDate);

  final cholesterol = CholesterolReading(
    id: 105,
    totalMgDl: 190,
    ldlMgDl: 110,
    hdlMgDl: 50,
    createdAt: testDate,
  );

  final weight = WeightReading(id: 106, readingKg: 78.5, createdAt: testDate);

  final enL10n = lookupAppLocalizations(const Locale('en'));

  group('HistoryEntryActionHandler.readingId', () {
    test('extracts id for GlucoseReading', () {
      expect(HistoryEntryActionHandler.readingId(glucose), 101);
    });

    test('extracts id for HbA1cReading', () {
      expect(HistoryEntryActionHandler.readingId(hba1c), 102);
    });

    test('extracts id for BloodPressureReading', () {
      expect(HistoryEntryActionHandler.readingId(bp), 103);
    });

    test('extracts id for KetoneReading', () {
      expect(HistoryEntryActionHandler.readingId(ketone), 104);
    });

    test('extracts id for CholesterolReading', () {
      expect(HistoryEntryActionHandler.readingId(cholesterol), 105);
    });

    test('extracts id for WeightReading', () {
      expect(HistoryEntryActionHandler.readingId(weight), 106);
    });

    test('returns 0 for unrecognized reading object', () {
      expect(HistoryEntryActionHandler.readingId(Object()), 0);
    });
  });

  group('HistoryEntryActionHandler.deleteConfirmMessage', () {
    test('returns matching localized strings for all MetricTypes', () {
      expect(
        HistoryEntryActionHandler.deleteConfirmMessage(
          MetricType.glucose,
          enL10n,
        ),
        enL10n.deleteReadingConfirmationMessage,
      );
      expect(
        HistoryEntryActionHandler.deleteConfirmMessage(
          MetricType.hba1c,
          enL10n,
        ),
        enL10n.deleteHba1cConfirm,
      );
      expect(
        HistoryEntryActionHandler.deleteConfirmMessage(
          MetricType.bloodPressure,
          enL10n,
        ),
        enL10n.deleteBloodPressureConfirm,
      );
      expect(
        HistoryEntryActionHandler.deleteConfirmMessage(
          MetricType.ketones,
          enL10n,
        ),
        enL10n.deleteKetonesConfirm,
      );
      expect(
        HistoryEntryActionHandler.deleteConfirmMessage(
          MetricType.cholesterol,
          enL10n,
        ),
        enL10n.deleteCholesterolConfirm,
      );
      expect(
        HistoryEntryActionHandler.deleteConfirmMessage(
          MetricType.weight,
          enL10n,
        ),
        enL10n.deleteWeightConfirm,
      );
    });
  });

  group('HistoryEntryActionHandler.deleteSuccessMessage', () {
    test('returns matching localized strings for all MetricTypes', () {
      expect(
        HistoryEntryActionHandler.deleteSuccessMessage(
          MetricType.glucose,
          enL10n,
        ),
        enL10n.glucoseReadingDeleted,
      );
      expect(
        HistoryEntryActionHandler.deleteSuccessMessage(
          MetricType.hba1c,
          enL10n,
        ),
        enL10n.hba1cDeletedSuccess,
      );
      expect(
        HistoryEntryActionHandler.deleteSuccessMessage(
          MetricType.bloodPressure,
          enL10n,
        ),
        enL10n.bpDeletedSuccess,
      );
      expect(
        HistoryEntryActionHandler.deleteSuccessMessage(
          MetricType.ketones,
          enL10n,
        ),
        enL10n.ketonesDeletedSuccess,
      );
      expect(
        HistoryEntryActionHandler.deleteSuccessMessage(
          MetricType.cholesterol,
          enL10n,
        ),
        enL10n.cholesterolDeletedSuccess,
      );
      expect(
        HistoryEntryActionHandler.deleteSuccessMessage(
          MetricType.weight,
          enL10n,
        ),
        enL10n.weightDeletedSuccess,
      );
    });
  });

  group('HistoryEntryActionHandler.deleteEntry and restoreEntry', () {
    late MockGlucoseReadingRepository mockGlucoseRepo;
    late MockHbA1cReadingRepository mockHbA1cRepo;
    late MockBloodPressureReadingRepository mockBpRepo;
    late MockKetoneReadingRepository mockKetoneRepo;
    late MockCholesterolReadingRepository mockCholesterolRepo;
    late MockWeightReadingRepository mockWeightRepo;

    setUp(() {
      mockGlucoseRepo = MockGlucoseReadingRepository();
      mockHbA1cRepo = MockHbA1cReadingRepository();
      mockBpRepo = MockBloodPressureReadingRepository();
      mockKetoneRepo = MockKetoneReadingRepository();
      mockCholesterolRepo = MockCholesterolReadingRepository();
      mockWeightRepo = MockWeightReadingRepository();

      when(
        () => mockGlucoseRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockHbA1cRepo.watchAll()).thenAnswer((_) => Stream.value([]));
      when(() => mockBpRepo.watchAll()).thenAnswer((_) => Stream.value([]));
      when(() => mockKetoneRepo.watchAll()).thenAnswer((_) => Stream.value([]));
      when(
        () => mockCholesterolRepo.watchAll(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockWeightRepo.watchAll()).thenAnswer((_) => Stream.value([]));
    });

    Widget buildTestHarness(void Function(WidgetRef) onReady) {
      return ProviderScope(
        overrides: [
          glucoseReadingRepositoryProvider.overrideWithValue(mockGlucoseRepo),
          hbA1cReadingRepositoryProvider.overrideWithValue(mockHbA1cRepo),
          bloodPressureReadingRepositoryProvider.overrideWithValue(mockBpRepo),
          ketoneReadingRepositoryProvider.overrideWithValue(mockKetoneRepo),
          cholesterolReadingRepositoryProvider.overrideWithValue(
            mockCholesterolRepo,
          ),
          weightReadingRepositoryProvider.overrideWithValue(mockWeightRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                onReady(ref);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    }

    testWidgets('deleteEntry delegates delete to corresponding repository', (
      tester,
    ) async {
      when(
        () => mockGlucoseRepo.delete(101),
      ).thenAnswer((_) async => (true, null));
      when(
        () => mockHbA1cRepo.delete(102),
      ).thenAnswer((_) async => (true, null));
      when(() => mockBpRepo.delete(103)).thenAnswer((_) async => (true, null));
      when(
        () => mockKetoneRepo.delete(104),
      ).thenAnswer((_) async => (true, null));
      when(
        () => mockCholesterolRepo.delete(105),
      ).thenAnswer((_) async => (true, null));
      when(
        () => mockWeightRepo.delete(106),
      ).thenAnswer((_) async => (true, null));

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        buildTestHarness((ref) {
          capturedRef = ref;
        }),
      );

      // Glucose
      await HistoryEntryActionHandler.deleteEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.glucose,
          createdAt: testDate,
          reading: glucose,
        ),
      );
      verify(() => mockGlucoseRepo.delete(101)).called(1);

      // HbA1c
      await HistoryEntryActionHandler.deleteEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.hba1c,
          createdAt: testDate,
          reading: hba1c,
        ),
      );
      verify(() => mockHbA1cRepo.delete(102)).called(1);

      // Blood Pressure
      await HistoryEntryActionHandler.deleteEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.bloodPressure,
          createdAt: testDate,
          reading: bp,
        ),
      );
      verify(() => mockBpRepo.delete(103)).called(1);

      // Ketones
      await HistoryEntryActionHandler.deleteEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.ketones,
          createdAt: testDate,
          reading: ketone,
        ),
      );
      verify(() => mockKetoneRepo.delete(104)).called(1);

      // Cholesterol
      await HistoryEntryActionHandler.deleteEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.cholesterol,
          createdAt: testDate,
          reading: cholesterol,
        ),
      );
      verify(() => mockCholesterolRepo.delete(105)).called(1);

      // Weight
      await HistoryEntryActionHandler.deleteEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.weight,
          createdAt: testDate,
          reading: weight,
        ),
      );
      verify(() => mockWeightRepo.delete(106)).called(1);

      // Unrecognized reading
      await HistoryEntryActionHandler.deleteEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.glucose,
          createdAt: testDate,
          reading: Object(),
        ),
      );
    });

    testWidgets('restoreEntry delegates add to corresponding repository', (
      tester,
    ) async {
      when(
        () => mockGlucoseRepo.add(glucose),
      ).thenAnswer((_) async => (true, null));
      when(
        () => mockHbA1cRepo.add(hba1c),
      ).thenAnswer((_) async => (true, null));
      when(() => mockBpRepo.add(bp)).thenAnswer((_) async => (true, null));
      when(
        () => mockKetoneRepo.add(ketone),
      ).thenAnswer((_) async => (true, null));
      when(
        () => mockCholesterolRepo.add(cholesterol),
      ).thenAnswer((_) async => (true, null));
      when(
        () => mockWeightRepo.add(weight),
      ).thenAnswer((_) async => (true, null));

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        buildTestHarness((ref) {
          capturedRef = ref;
        }),
      );

      // Glucose
      await HistoryEntryActionHandler.restoreEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.glucose,
          createdAt: testDate,
          reading: glucose,
        ),
      );
      verify(() => mockGlucoseRepo.add(glucose)).called(1);

      // HbA1c
      await HistoryEntryActionHandler.restoreEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.hba1c,
          createdAt: testDate,
          reading: hba1c,
        ),
      );
      verify(() => mockHbA1cRepo.add(hba1c)).called(1);

      // Blood Pressure
      await HistoryEntryActionHandler.restoreEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.bloodPressure,
          createdAt: testDate,
          reading: bp,
        ),
      );
      verify(() => mockBpRepo.add(bp)).called(1);

      // Ketones
      await HistoryEntryActionHandler.restoreEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.ketones,
          createdAt: testDate,
          reading: ketone,
        ),
      );
      verify(() => mockKetoneRepo.add(ketone)).called(1);

      // Cholesterol
      await HistoryEntryActionHandler.restoreEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.cholesterol,
          createdAt: testDate,
          reading: cholesterol,
        ),
      );
      verify(() => mockCholesterolRepo.add(cholesterol)).called(1);

      // Weight
      await HistoryEntryActionHandler.restoreEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.weight,
          createdAt: testDate,
          reading: weight,
        ),
      );
      verify(() => mockWeightRepo.add(weight)).called(1);

      // Unrecognized reading
      await HistoryEntryActionHandler.restoreEntry(
        capturedRef,
        HistoryEntry(
          type: MetricType.glucose,
          createdAt: testDate,
          reading: Object(),
        ),
      );
    });
  });

  group('HistoryEntryActionHandler.confirmDelete', () {
    Widget buildTestApp(void Function(BuildContext) onTrigger) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onTrigger(context),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('resolves to true when delete button is pressed in dialog', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        buildTestApp((context) async {
          result = await HistoryEntryActionHandler.confirmDelete(
            context,
            MetricType.glucose,
          );
        }),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(enL10n.deleteReadingConfirmationTitle), findsOneWidget);
      expect(
        find.text(enL10n.deleteReadingConfirmationMessage),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, enL10n.delete));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('resolves to false when cancel button is pressed in dialog', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        buildTestApp((context) async {
          result = await HistoryEntryActionHandler.confirmDelete(
            context,
            MetricType.hba1c,
          );
        }),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(enL10n.deleteHba1cConfirm), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, enL10n.cancel));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
