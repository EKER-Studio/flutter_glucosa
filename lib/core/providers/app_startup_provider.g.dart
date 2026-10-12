// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_startup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pre-warms and initializes all critical asynchronous dependencies before UI rendering.
///
/// Watches [isarDbProvider] to ensure local database collections are open and ready,
/// and pre-loads persisted BLE glucometer preferences.
/// Returns a [Future] completing when all startup services are initialized.

@ProviderFor(appStartup)
final appStartupProvider = AppStartupProvider._();

/// Pre-warms and initializes all critical asynchronous dependencies before UI rendering.
///
/// Watches [isarDbProvider] to ensure local database collections are open and ready,
/// and pre-loads persisted BLE glucometer preferences.
/// Returns a [Future] completing when all startup services are initialized.

final class AppStartupProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Pre-warms and initializes all critical asynchronous dependencies before UI rendering.
  ///
  /// Watches [isarDbProvider] to ensure local database collections are open and ready,
  /// and pre-loads persisted BLE glucometer preferences.
  /// Returns a [Future] completing when all startup services are initialized.
  AppStartupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStartupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStartupHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return appStartup(ref);
  }
}

String _$appStartupHash() => r'5845f1658379cb689b32fdebec931422173f9c37';
