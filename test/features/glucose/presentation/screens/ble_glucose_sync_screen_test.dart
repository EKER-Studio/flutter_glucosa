import 'package:flutter/material.dart';
import 'package:flutter_glucosa/core/presentation/theme/app_theme.dart';
import 'package:flutter_glucosa/features/glucose/data/providers/ble_glucose_sync_providers.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/ble_device_info.dart';
import 'package:flutter_glucosa/features/glucose/domain/repositories/ble_glucose_sync_repository.dart';
import 'package:flutter_glucosa/features/glucose/presentation/providers/ble_glucose_scan_notifier.dart';
import 'package:flutter_glucosa/features/glucose/presentation/screens/ble_glucose_sync_screen.dart';
import 'package:flutter_glucosa/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBleGlucoseSyncRepository extends Mock
    implements BleGlucoseSyncRepository {}

void main() {
  late MockBleGlucoseSyncRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
  });

  setUp(() {
    mockRepository = MockBleGlucoseSyncRepository();
    when(() => mockRepository.stopScan()).thenAnswer((_) async {});
    when(
      () => mockRepository.scanDevices(timeout: any(named: 'timeout')),
    ).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidget({List<dynamic> overrides = const []}) {
    return ProviderScope(
      overrides: [
        bleGlucoseSyncRepositoryProvider.overrideWithValue(mockRepository),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BleGlucoseSyncScreen(),
      ),
    );
  }

  testWidgets('renders screen title and supported standard banner', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Bluetooth Glucometer'), findsOneWidget);
    expect(find.byIcon(Icons.bluetooth), findsOneWidget);
  });

  testWidgets('displays empty state card when no devices found', (
    tester,
  ) async {
    await tester.pumpWidget(
      createWidget(
        overrides: [
          bleGlucoseScanProvider.overrideWith(() => _FakeEmptyScanNotifier()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No glucometers found'), findsOneWidget);
    expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);
  });

  testWidgets('displays device card and triggers sync when tapped', (
    tester,
  ) async {
    const testDevice = BleDeviceInfo(
      id: 'mock-mac-123',
      name: 'Accu-Chek Instant',
      rssi: -58,
    );

    when(
      () => mockRepository.syncFromDevice('mock-mac-123'),
    ).thenAnswer((_) async => (3, null));

    await tester.pumpWidget(
      createWidget(
        overrides: [
          bleGlucoseScanProvider.overrideWith(
            () => _FakeFoundDeviceScanNotifier([testDevice]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accu-Chek Instant'), findsOneWidget);
    expect(find.text('RSSI: -58 dBm'), findsOneWidget);

    final syncButton = find.widgetWithText(FilledButton, 'Sync');
    expect(syncButton, findsOneWidget);

    await tester.tap(syncButton);
    await tester.pumpAndSettle();

    verify(() => mockRepository.syncFromDevice('mock-mac-123')).called(1);
    expect(
      find.text('Imported 3 new readings from Accu-Chek Instant.'),
      findsOneWidget,
    );
  });
}

class _FakeEmptyScanNotifier extends BleGlucoseScanNotifier {
  @override
  BleScanState build() => (devices: const <BleDeviceInfo>[], isScanning: false);
}

class _FakeFoundDeviceScanNotifier extends BleGlucoseScanNotifier {
  final List<BleDeviceInfo> _devices;
  _FakeFoundDeviceScanNotifier(this._devices);

  @override
  BleScanState build() => (devices: _devices, isScanning: false);

  @override
  void startScan({Duration timeout = const Duration(seconds: 15)}) {
    state = (devices: _devices, isScanning: false);
  }
}
