// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_ble_device_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier managing the remembered BLE glucometer state.

@ProviderFor(SavedBleDeviceNotifier)
final savedBleDeviceProvider = SavedBleDeviceNotifierProvider._();

/// Riverpod notifier managing the remembered BLE glucometer state.
final class SavedBleDeviceNotifierProvider
    extends $NotifierProvider<SavedBleDeviceNotifier, BleSavedDevice?> {
  /// Riverpod notifier managing the remembered BLE glucometer state.
  SavedBleDeviceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedBleDeviceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedBleDeviceNotifierHash();

  @$internal
  @override
  SavedBleDeviceNotifier create() => SavedBleDeviceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BleSavedDevice? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BleSavedDevice?>(value),
    );
  }
}

String _$savedBleDeviceNotifierHash() =>
    r'de88ca5fa7ea39de34aa7244874ce014751586b6';

/// Riverpod notifier managing the remembered BLE glucometer state.

abstract class _$SavedBleDeviceNotifier extends $Notifier<BleSavedDevice?> {
  BleSavedDevice? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BleSavedDevice?, BleSavedDevice?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BleSavedDevice?, BleSavedDevice?>,
              BleSavedDevice?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
