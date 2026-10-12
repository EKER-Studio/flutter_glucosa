// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ble_glucose_scan_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier managing Bluetooth LE discovery for compatible glucometers.

@ProviderFor(BleGlucoseScanNotifier)
final bleGlucoseScanProvider = BleGlucoseScanNotifierProvider._();

/// Riverpod notifier managing Bluetooth LE discovery for compatible glucometers.
final class BleGlucoseScanNotifierProvider
    extends $NotifierProvider<BleGlucoseScanNotifier, BleScanState> {
  /// Riverpod notifier managing Bluetooth LE discovery for compatible glucometers.
  BleGlucoseScanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bleGlucoseScanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bleGlucoseScanNotifierHash();

  @$internal
  @override
  BleGlucoseScanNotifier create() => BleGlucoseScanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BleScanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BleScanState>(value),
    );
  }
}

String _$bleGlucoseScanNotifierHash() =>
    r'0dc18af79ebb7bb9b50a4988637dc296a65b128a';

/// Riverpod notifier managing Bluetooth LE discovery for compatible glucometers.

abstract class _$BleGlucoseScanNotifier extends $Notifier<BleScanState> {
  BleScanState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BleScanState, BleScanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BleScanState, BleScanState>,
              BleScanState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
