import 'package:flutter_glucosa/core/domain/enums/meal_context.dart';
import 'package:flutter_glucosa/features/glucose/data/datasources/ble/gls_measurement_context_parser.dart';
import 'package:flutter_glucosa/features/glucose/data/datasources/ble/gls_measurement_parser.dart';
import 'package:flutter_glucosa/features/glucose/data/datasources/ble/ieee11073_float_parser.dart';
import 'package:flutter_glucosa/features/glucose/data/datasources/ble/racp_command_builder.dart';
import 'package:flutter_glucosa/features/glucose/data/datasources/ble/racp_response_parser.dart';
import 'package:flutter_glucosa/features/glucose/data/mappers/gls_record_mapper.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/gls_measurement_context.dart';
import 'package:flutter_glucosa/features/glucose/domain/entities/gls_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ieee11073FloatParser', () {
    test('parses normal positive integer with exponent 0', () {
      // 0x0051: mantissa = 0x051 (81), exponent = 0x0 (0) -> 81.0
      final result = Ieee11073FloatParser.parseSFloat([0x51, 0x00], 0);
      expect(result, closeTo(81.0, 0.001));
    });

    test('parses value with negative exponent', () {
      // 0xF051: mantissa = 0x051 (81), exponent = 0xF (-1) -> 8.1
      final result = Ieee11073FloatParser.parseSFloat([0x51, 0xF0], 0);
      expect(result, closeTo(8.1, 0.001));
    });

    test('parses value with negative mantissa', () {
      // 0x0FFB: mantissa = -5, exponent = 0 -> -5.0
      final result = Ieee11073FloatParser.parseSFloat([0xFB, 0x0F], 0);
      expect(result, closeTo(-5.0, 0.001));
    });

    test('handles special IEEE-11073 values', () {
      // NaN (0x07FF)
      expect(Ieee11073FloatParser.parseSFloat([0xFF, 0x07], 0)!.isNaN, isTrue);
      // +Infinity (0x07FE)
      expect(
        Ieee11073FloatParser.parseSFloat([0xFE, 0x07], 0),
        equals(double.infinity),
      );
      // -Infinity (0x0802)
      expect(
        Ieee11073FloatParser.parseSFloat([0x02, 0x08], 0),
        equals(double.negativeInfinity),
      );
      // NRes (0x0800)
      expect(Ieee11073FloatParser.parseSFloat([0x00, 0x08], 0), isNull);
    });

    test('returns null when byte buffer is insufficient', () {
      expect(Ieee11073FloatParser.parseSFloat([0x51], 0), isNull);
    });
  });

  group('GlsMeasurementParser', () {
    test('returns null for data shorter than 10 bytes', () {
      final data = List.filled(9, 0);
      expect(GlsMeasurementParser.parse(data), isNull);
    });

    test('parses record with only required fields', () {
      final data = [
        0x00, // Flags: no optional fields
        0x01, 0x00, // Sequence Number: 1
        0xE4, 0x07, // Year: 2020 (0x07E4)
        0x05, // Month: 5 (May)
        0x15, // Day: 21
        0x0A, // Hour: 10
        0x1E, // Minute: 30
        0x2D, // Second: 45
      ];

      final record = GlsMeasurementParser.parse(data);
      expect(record, isNotNull);
      expect(record!.sequenceNumber, equals(1));
      expect(record.timestamp, equals(DateTime(2020, 5, 21, 10, 30, 45)));
      expect(record.concentration, isNull);
      expect(record.sampleType, isNull);
      expect(record.sampleLocation, isNull);
      expect(record.sensorStatus, isNull);
      expect(record.contextInformationFollows, isFalse);
    });

    test('parses record with all optional fields (vector from nRF Toolbox)', () {
      final data = [
        0x1F, // Flags: all optional fields present (time offset, conc, mol/L, status, context)
        0x02, 0x00, // Sequence Number: 2
        0xE4, 0x07, // Year: 2020
        0x05, // Month: May
        0x15, // Day: 21
        0x0A, // Hour: 10
        0x1E, // Minute: 30
        0x2D, // Second: 45
        0x00, 0x00, // Time Offset: 0 minutes
        0x51, 0x00, // Glucose concentration: 81.0 (IEEE 11073)
        0x14, // Sample type: 4 (Venous Plasma), Location: 1 (Finger)
        0x06, 0x00, // Sensor Status: 6
      ];

      final record = GlsMeasurementParser.parse(data);
      expect(record, isNotNull);
      expect(record!.sequenceNumber, equals(2));
      expect(record.timestamp, equals(DateTime(2020, 5, 21, 10, 30, 45)));
      expect(record.concentration, closeTo(81.0, 0.001));
      expect(record.isMolPerLiter, isTrue);
      expect(record.sampleType, equals('Venous Plasma'));
      expect(record.sampleLocation, equals('Finger'));
      expect(record.sensorStatus, equals(6));
      expect(record.contextInformationFollows, isTrue);
    });

    test('applies positive and negative time offset correctly', () {
      final data = [
        0x01, // Flags: time offset present
        0x05, 0x00, // Sequence Number: 5
        0xE4, 0x07, // Year: 2020
        0x01, 0x01, 0x0C, 0x00, 0x00, // 2020-01-01 12:00:00
        0x1E, 0x00, // Time offset: +30 minutes
      ];

      final record = GlsMeasurementParser.parse(data);
      expect(record, isNotNull);
      expect(record!.timestamp, equals(DateTime(2020, 1, 1, 12, 30, 0)));
    });

    test('returns null for incomplete optional fields', () {
      final incompleteData = [
        0x0F, // Flags: requires 10 + 2 (time) + 3 (conc) + 2 (status) = 17 bytes
        0x03, 0x00, // Seq
        0xE4, 0x07, 0x05, 0x15, 0x0A, 0x1E, 0x2D, // DateTime
        0x05, 0x00, // Time offset
        0xCD, 0xCC, // Missing type/location and status
      ];
      expect(GlsMeasurementParser.parse(incompleteData), isNull);
    });
  });

  group('GlsMeasurementContextParser', () {
    test('returns null for data shorter than 3 bytes', () {
      expect(GlsMeasurementContextParser.parse([0x00, 0x01]), isNull);
    });

    test('parses minimal context packet without optional fields', () {
      final data = [
        0x00, // Flags: none
        0x07, 0x00, // Sequence Number: 7
      ];
      final context = GlsMeasurementContextParser.parse(data);
      expect(context, isNotNull);
      expect(context!.sequenceNumber, equals(7));
      expect(context.mealType, isNull);
      expect(context.carbohydrateType, isNull);
      expect(context.medicationType, isNull);
    });

    test('parses context with meal, carbs, medication, tester, and HbA1c', () {
      final data = [
        0x77, // Flags: carbs(0x01) | meal(0x02) | testerHealth(0x04) | med(0x10) | medUnitLiter(0x20) | hbA1c(0x40) = 0x77
        0x0A, 0x00, // Sequence Number: 10
        0x01, // Carb ID: 1 (Breakfast)
        0x2D, 0x00, // Carb amount: 45.0 grams (0x002D)
        0x01, // Meal ID: 1 (Preprandial)
        0x14, // Tester: 1 (Self), Health: 4 (Under Stress) -> 0x14
        0x01, // Medication ID: 1 (Rapid-acting insulin)
        0x04, 0x00, // Medication Amount: 4.0 (0x0004)
        0x3E, 0xF0, // HbA1c: 6.2% (0xF03E: mantissa 62, exp -1)
      ];

      final context = GlsMeasurementContextParser.parse(data);
      expect(context, isNotNull);
      expect(context!.sequenceNumber, equals(10));
      expect(context.carbohydrateType, equals('Breakfast'));
      expect(context.carbohydrateGrams, closeTo(45.0, 0.001));
      expect(context.mealType, equals('Preprandial'));
      expect(context.tester, equals('Self'));
      expect(context.health, equals('Under Stress'));
      expect(context.medicationType, equals('Rapid-acting insulin'));
      expect(context.medicationAmount, closeTo(4.0, 0.001));
      expect(context.isMedicationInLiters, isTrue);
      expect(context.hbA1cPercentage, closeTo(6.2, 0.01));
    });

    test('returns null when payload is shorter than flags require', () {
      final truncated = [
        0x01, // Flags: carb present (requires 3 extra bytes)
        0x01, 0x00, // Sequence Number: 1
        0x01, // Only carb ID, missing carb amount
      ];
      expect(GlsMeasurementContextParser.parse(truncated), isNull);
    });
  });

  group('GlsRecordMapper with context', () {
    test('maps Fasting context to MealContext.fasting', () {
      final record = GlsRecord(
        sequenceNumber: 1,
        timestamp: DateTime(2026, 5, 10, 8, 0),
        concentration: 0.001,
        context: const GlsMeasurementContext(
          sequenceNumber: 1,
          mealType: 'Fasting',
        ),
      );

      final domain = record.toDomain();
      expect(domain.mealContext, equals(MealContext.fasting));
      expect(domain.readingMgDl, equals(100));
    });

    test('maps Preprandial morning context to beforeBreakfast', () {
      final record = GlsRecord(
        sequenceNumber: 2,
        timestamp: DateTime(2026, 5, 10, 8, 30),
        concentration: 0.001,
        context: const GlsMeasurementContext(
          sequenceNumber: 2,
          mealType: 'Preprandial',
        ),
      );

      final domain = record.toDomain();
      expect(domain.mealContext, equals(MealContext.beforeBreakfast));
    });

    test('maps Postprandial evening context to afterDinner', () {
      final record = GlsRecord(
        sequenceNumber: 3,
        timestamp: DateTime(2026, 5, 10, 19, 0),
        concentration: 0.001,
        context: const GlsMeasurementContext(
          sequenceNumber: 3,
          mealType: 'Postprandial',
        ),
      );

      final domain = record.toDomain();
      expect(domain.mealContext, equals(MealContext.afterDinner));
    });

    test('populates notes with carbohydrates, medication, and health', () {
      final record = GlsRecord(
        sequenceNumber: 4,
        timestamp: DateTime(2026, 5, 10, 12, 30),
        concentration: 0.001,
        sampleLocation: 'Finger',
        context: const GlsMeasurementContext(
          sequenceNumber: 4,
          mealType: 'Postprandial',
          carbohydrateType: 'Lunch',
          carbohydrateGrams: 50.0,
          medicationType: 'Rapid-acting insulin',
          medicationAmount: 5.0,
          health: 'Under Stress',
        ),
      );

      final domain = record.toDomain();
      expect(domain.mealContext, equals(MealContext.afterLunch));
      expect(domain.notes, contains('Finger'));
      expect(domain.notes, contains('Carbs: 50.0g (Lunch)'));
      expect(
        domain.notes,
        contains('Medication: 5.0mg (Rapid-acting insulin)'),
      );
      expect(domain.notes, contains('Health: Under Stress'));
    });
  });

  group('RacpCommandBuilder', () {
    test('builds reportNumberOfAllStoredRecords command', () {
      expect(
        RacpCommandBuilder.reportNumberOfAllStoredRecords(),
        equals([4, 1]),
      );
    });

    test('builds reportAllStoredRecords command', () {
      expect(RacpCommandBuilder.reportAllStoredRecords(), equals([1, 1]));
    });

    test('builds reportFirstStoredRecord command', () {
      expect(RacpCommandBuilder.reportFirstStoredRecord(), equals([1, 5]));
    });

    test('builds reportLastStoredRecord command', () {
      expect(RacpCommandBuilder.reportLastStoredRecord(), equals([1, 6]));
    });

    test('builds reportStoredRecordsGreaterThanOrEqualTo command', () {
      expect(
        RacpCommandBuilder.reportStoredRecordsGreaterThanOrEqualTo(300),
        equals([1, 3, 1, 0x2C, 0x01]), // 300 = 0x012C
      );
    });

    test('builds abortOperation command', () {
      expect(RacpCommandBuilder.abortOperation(), equals([3, 0]));
    });
  });

  group('RacpResponseParser', () {
    test('parses numberOfRecords response', () {
      final response = RacpResponseParser.parse([5, 0, 15, 0]);
      expect(response, isA<RacpNumberOfRecordsResponse>());
      expect((response as RacpNumberOfRecordsResponse).count, equals(15));
    });

    test('parses success response', () {
      final response = RacpResponseParser.parse([6, 0, 1, 1]);
      expect(response, isA<RacpGeneralResponse>());
      final general = response as RacpGeneralResponse;
      expect(general.requestOpCode, equals(1));
      expect(general.responseCode, equals(1));
      expect(general.isSuccess, isTrue);
      expect(general.isNoRecordsFound, isFalse);
    });

    test('parses no records found response', () {
      final response = RacpResponseParser.parse([6, 0, 1, 6]);
      expect(response, isA<RacpGeneralResponse>());
      final general = response as RacpGeneralResponse;
      expect(general.isSuccess, isFalse);
      expect(general.isNoRecordsFound, isTrue);
    });

    test('parses op code not supported response', () {
      final response = RacpResponseParser.parse([6, 0, 4, 2]);
      expect(response, isA<RacpGeneralResponse>());
      final general = response as RacpGeneralResponse;
      expect(general.isOpCodeNotSupported, isTrue);
    });

    test('returns null for malformed or short data', () {
      expect(RacpResponseParser.parse([6, 0]), isNull);
      expect(RacpResponseParser.parse([99, 0, 0, 0]), isNull);
    });
  });

  group('GlsRecord mg/dL conversion', () {
    test('converts kg/L to mg/dL correctly', () {
      // 0.00100 kg/L = 100 mg/dL
      final record = GlsRecord(
        sequenceNumber: 1,
        timestamp: DateTime(2026, 1, 1),
        concentration: 0.00100,
        isMolPerLiter: false,
      );
      expect(record.concentrationMgDl, equals(100));
    });

    test('converts mol/L to mg/dL correctly', () {
      // 0.0055 mol/L = 5.5 mmol/L -> 5.5 * 18.0182 = 99.1 mg/dL -> 99 mg/dL
      final record = GlsRecord(
        sequenceNumber: 1,
        timestamp: DateTime(2026, 1, 1),
        concentration: 0.0055,
        isMolPerLiter: true,
      );
      expect(record.concentrationMgDl, equals(99));
    });
  });
}
