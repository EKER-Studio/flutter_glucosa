// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ble_glucose_sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dependency injection provider supplying a [BleGlucoseDataSource] instance.

@ProviderFor(bleGlucoseDataSource)
final bleGlucoseDataSourceProvider = BleGlucoseDataSourceProvider._();

/// Dependency injection provider supplying a [BleGlucoseDataSource] instance.

final class BleGlucoseDataSourceProvider
    extends
        $FunctionalProvider<
          BleGlucoseDataSource,
          BleGlucoseDataSource,
          BleGlucoseDataSource
        >
    with $Provider<BleGlucoseDataSource> {
  /// Dependency injection provider supplying a [BleGlucoseDataSource] instance.
  BleGlucoseDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bleGlucoseDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bleGlucoseDataSourceHash();

  @$internal
  @override
  $ProviderElement<BleGlucoseDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BleGlucoseDataSource create(Ref ref) {
    return bleGlucoseDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BleGlucoseDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BleGlucoseDataSource>(value),
    );
  }
}

String _$bleGlucoseDataSourceHash() =>
    r'3ec1695de5a3b064d20bb04b6220569f9497e979';

/// Dependency injection provider supplying a [BleGlucoseSyncRepository] instance.

@ProviderFor(bleGlucoseSyncRepository)
final bleGlucoseSyncRepositoryProvider = BleGlucoseSyncRepositoryProvider._();

/// Dependency injection provider supplying a [BleGlucoseSyncRepository] instance.

final class BleGlucoseSyncRepositoryProvider
    extends
        $FunctionalProvider<
          BleGlucoseSyncRepository,
          BleGlucoseSyncRepository,
          BleGlucoseSyncRepository
        >
    with $Provider<BleGlucoseSyncRepository> {
  /// Dependency injection provider supplying a [BleGlucoseSyncRepository] instance.
  BleGlucoseSyncRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bleGlucoseSyncRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bleGlucoseSyncRepositoryHash();

  @$internal
  @override
  $ProviderElement<BleGlucoseSyncRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BleGlucoseSyncRepository create(Ref ref) {
    return bleGlucoseSyncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BleGlucoseSyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BleGlucoseSyncRepository>(value),
    );
  }
}

String _$bleGlucoseSyncRepositoryHash() =>
    r'88252ba8246a6d0e4d94f74ab2f452f4e71a6ae2';
