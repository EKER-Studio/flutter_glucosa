import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/ble_glucose_sync_repository.dart';
import '../datasources/ble/ble_glucose_data_source.dart';
import '../repositories/ble_glucose_sync_repository_impl.dart';
import 'glucose_reading_repository_provider.dart';

part 'ble_glucose_sync_providers.g.dart';

/// Dependency injection provider supplying a [BleGlucoseDataSource] instance.
@Riverpod(keepAlive: true)
BleGlucoseDataSource bleGlucoseDataSource(Ref ref) {
  return const BleGlucoseDataSourceImpl();
}

/// Dependency injection provider supplying a [BleGlucoseSyncRepository] instance.
@Riverpod(keepAlive: true)
BleGlucoseSyncRepository bleGlucoseSyncRepository(Ref ref) {
  final dataSource = ref.watch(bleGlucoseDataSourceProvider);
  final readingRepository = ref.watch(glucoseReadingRepositoryProvider);
  return BleGlucoseSyncRepositoryImpl(
    dataSource: dataSource,
    readingRepository: readingRepository,
  );
}
