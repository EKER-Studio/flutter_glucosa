// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ble_glucose_sync_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier managing synchronization state with a target BLE glucometer.

@ProviderFor(BleGlucoseSyncNotifier)
final bleGlucoseSyncProvider = BleGlucoseSyncNotifierProvider._();

/// Riverpod notifier managing synchronization state with a target BLE glucometer.
final class BleGlucoseSyncNotifierProvider
    extends $NotifierProvider<BleGlucoseSyncNotifier, BleSyncStatus> {
  /// Riverpod notifier managing synchronization state with a target BLE glucometer.
  BleGlucoseSyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bleGlucoseSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bleGlucoseSyncNotifierHash();

  @$internal
  @override
  BleGlucoseSyncNotifier create() => BleGlucoseSyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BleSyncStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BleSyncStatus>(value),
    );
  }
}

String _$bleGlucoseSyncNotifierHash() =>
    r'8a214dde7dbec73f860f9fd23d3c14138fbd087b';

/// Riverpod notifier managing synchronization state with a target BLE glucometer.

abstract class _$BleGlucoseSyncNotifier extends $Notifier<BleSyncStatus> {
  BleSyncStatus build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BleSyncStatus, BleSyncStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BleSyncStatus, BleSyncStatus>,
              BleSyncStatus,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
