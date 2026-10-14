// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dependency injection provider supplying the shared [HealthService] instance.

@ProviderFor(healthService)
final healthServiceProvider = HealthServiceProvider._();

/// Dependency injection provider supplying the shared [HealthService] instance.

final class HealthServiceProvider
    extends $FunctionalProvider<HealthService, HealthService, HealthService>
    with $Provider<HealthService> {
  /// Dependency injection provider supplying the shared [HealthService] instance.
  HealthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthServiceHash();

  @$internal
  @override
  $ProviderElement<HealthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HealthService create(Ref ref) {
    return healthService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthService>(value),
    );
  }
}

String _$healthServiceHash() => r'faec1d1cc3f0391ef32ac8a3dc6d69b2f0f77555';
