import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'health_service.dart';

part 'health_service_provider.g.dart';

/// Dependency injection provider supplying the shared [HealthService] instance.
@Riverpod(keepAlive: true)
HealthService healthService(Ref ref) {
  return NativeHealthService();
}
