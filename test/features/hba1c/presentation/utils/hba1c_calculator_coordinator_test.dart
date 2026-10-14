import 'package:flutter_glucosa/core/domain/enums/glucose_unit.dart';
import 'package:flutter_glucosa/core/domain/enums/hba1c_unit.dart';
import 'package:flutter_glucosa/features/hba1c/presentation/utils/hba1c_calculator_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HbA1cCalculatorCoordinator', () {
    group('calculateHbA1cFromGlucose', () {
      test(
        'returns empty string for empty, whitespace, or non-numeric input',
        () {
          expect(
            HbA1cCalculatorCoordinator.calculateHbA1cFromGlucose(
              glucoseText: '',
              glucoseUnit: GlucoseUnit.mgDl,
              hba1cUnit: HbA1cUnit.percentage,
            ),
            '',
          );
          expect(
            HbA1cCalculatorCoordinator.calculateHbA1cFromGlucose(
              glucoseText: '   ',
              glucoseUnit: GlucoseUnit.mgDl,
              hba1cUnit: HbA1cUnit.percentage,
            ),
            '',
          );
          expect(
            HbA1cCalculatorCoordinator.calculateHbA1cFromGlucose(
              glucoseText: 'invalid',
              glucoseUnit: GlucoseUnit.mgDl,
              hba1cUnit: HbA1cUnit.percentage,
            ),
            '',
          );
        },
      );

      test('returns empty string for zero or negative glucose values', () {
        expect(
          HbA1cCalculatorCoordinator.calculateHbA1cFromGlucose(
            glucoseText: '0',
            glucoseUnit: GlucoseUnit.mgDl,
            hba1cUnit: HbA1cUnit.percentage,
          ),
          '',
        );
        expect(
          HbA1cCalculatorCoordinator.calculateHbA1cFromGlucose(
            glucoseText: '-120',
            glucoseUnit: GlucoseUnit.mgDl,
            hba1cUnit: HbA1cUnit.percentage,
          ),
          '',
        );
      });

      test('calculates HbA1c percentage from mg/dL glucose', () {
        // (154 + 46.7) / 28.7 = 6.993... -> 6.99
        final result = HbA1cCalculatorCoordinator.calculateHbA1cFromGlucose(
          glucoseText: '154',
          glucoseUnit: GlucoseUnit.mgDl,
          hba1cUnit: HbA1cUnit.percentage,
        );
        expect(result, '6.99');
      });

      test('calculates HbA1c mmol/mol from mg/dL glucose', () {
        // estHbA1c = 6.99 -> (6.99 - 2.152) / 0.09148 = 52.885... -> 52.9
        final result = HbA1cCalculatorCoordinator.calculateHbA1cFromGlucose(
          glucoseText: '154',
          glucoseUnit: GlucoseUnit.mgDl,
          hba1cUnit: HbA1cUnit.mmolMol,
        );
        expect(result, '52.9');
      });

      test(
        'calculates HbA1c from mmol/L glucose with comma decimal support',
        () {
          // 10.0 mmol/L -> 180 mg/dL -> estHbA1c: (180 + 46.7) / 28.7 = 7.90
          final result = HbA1cCalculatorCoordinator.calculateHbA1cFromGlucose(
            glucoseText: '10,0',
            glucoseUnit: GlucoseUnit.mmolL,
            hba1cUnit: HbA1cUnit.percentage,
          );
          expect(result, '7.90');
        },
      );
    });

    group('calculateGlucoseFromHbA1c', () {
      test('returns empty string for empty, whitespace, or invalid input', () {
        expect(
          HbA1cCalculatorCoordinator.calculateGlucoseFromHbA1c(
            hba1cText: '',
            hba1cUnit: HbA1cUnit.percentage,
            glucoseUnit: GlucoseUnit.mgDl,
          ),
          '',
        );
        expect(
          HbA1cCalculatorCoordinator.calculateGlucoseFromHbA1c(
            hba1cText: '   ',
            hba1cUnit: HbA1cUnit.percentage,
            glucoseUnit: GlucoseUnit.mgDl,
          ),
          '',
        );
        expect(
          HbA1cCalculatorCoordinator.calculateGlucoseFromHbA1c(
            hba1cText: 'abc',
            hba1cUnit: HbA1cUnit.percentage,
            glucoseUnit: GlucoseUnit.mgDl,
          ),
          '',
        );
        expect(
          HbA1cCalculatorCoordinator.calculateGlucoseFromHbA1c(
            hba1cText: '0',
            hba1cUnit: HbA1cUnit.percentage,
            glucoseUnit: GlucoseUnit.mgDl,
          ),
          '',
        );
        expect(
          HbA1cCalculatorCoordinator.calculateGlucoseFromHbA1c(
            hba1cText: '-5',
            hba1cUnit: HbA1cUnit.percentage,
            glucoseUnit: GlucoseUnit.mgDl,
          ),
          '',
        );
      });

      test('calculates glucose mg/dL from HbA1c percentage', () {
        // (28.7 * 7.0) - 46.7 = 200.9 - 46.7 = 154.2 -> round to 154
        final result = HbA1cCalculatorCoordinator.calculateGlucoseFromHbA1c(
          hba1cText: '7.0',
          hba1cUnit: HbA1cUnit.percentage,
          glucoseUnit: GlucoseUnit.mgDl,
        );
        expect(result, '154');
      });

      test('calculates glucose mmol/L from HbA1c percentage with comma', () {
        // 7.0 % -> estGlucoseMgDl = 154.2 -> mgDlToMmolL(154.2) -> 8.6
        final result = HbA1cCalculatorCoordinator.calculateGlucoseFromHbA1c(
          hba1cText: '7,0',
          hba1cUnit: HbA1cUnit.percentage,
          glucoseUnit: GlucoseUnit.mmolL,
        );
        expect(result, '8.6');
      });

      test('calculates glucose from HbA1c mmol/mol', () {
        // 53 mmol/mol -> 7.0 % -> 154 mg/dL
        final result = HbA1cCalculatorCoordinator.calculateGlucoseFromHbA1c(
          hba1cText: '53.0',
          hba1cUnit: HbA1cUnit.mmolMol,
          glucoseUnit: GlucoseUnit.mgDl,
        );
        expect(result, '154');
      });
    });

    group('convertGlucoseDisplay', () {
      test(
        'returns original string if empty, non-positive, or non-numeric',
        () {
          expect(
            HbA1cCalculatorCoordinator.convertGlucoseDisplay(
              text: '',
              oldUnit: GlucoseUnit.mgDl,
              newUnit: GlucoseUnit.mmolL,
            ),
            '',
          );
          expect(
            HbA1cCalculatorCoordinator.convertGlucoseDisplay(
              text: 'invalid',
              oldUnit: GlucoseUnit.mgDl,
              newUnit: GlucoseUnit.mmolL,
            ),
            'invalid',
          );
          expect(
            HbA1cCalculatorCoordinator.convertGlucoseDisplay(
              text: '0',
              oldUnit: GlucoseUnit.mgDl,
              newUnit: GlucoseUnit.mmolL,
            ),
            '0',
          );
        },
      );

      test('converts mg/dL to mmol/L with formatting', () {
        expect(
          HbA1cCalculatorCoordinator.convertGlucoseDisplay(
            text: '180',
            oldUnit: GlucoseUnit.mgDl,
            newUnit: GlucoseUnit.mmolL,
          ),
          '10.0',
        );
        expect(
          HbA1cCalculatorCoordinator.convertGlucoseDisplay(
            text: '100,0',
            oldUnit: GlucoseUnit.mgDl,
            newUnit: GlucoseUnit.mmolL,
          ),
          '5.6',
        );
      });

      test('converts mmol/L to mg/dL with formatting', () {
        expect(
          HbA1cCalculatorCoordinator.convertGlucoseDisplay(
            text: '10.0',
            oldUnit: GlucoseUnit.mmolL,
            newUnit: GlucoseUnit.mgDl,
          ),
          '180',
        );
        expect(
          HbA1cCalculatorCoordinator.convertGlucoseDisplay(
            text: '5,6',
            oldUnit: GlucoseUnit.mmolL,
            newUnit: GlucoseUnit.mgDl,
          ),
          '101',
        );
      });

      test('returns original text when units are unchanged', () {
        expect(
          HbA1cCalculatorCoordinator.convertGlucoseDisplay(
            text: '120',
            oldUnit: GlucoseUnit.mgDl,
            newUnit: GlucoseUnit.mgDl,
          ),
          '120',
        );
      });
    });

    group('convertHbA1cDisplay', () {
      test(
        'returns original string if empty, non-positive, or non-numeric',
        () {
          expect(
            HbA1cCalculatorCoordinator.convertHbA1cDisplay(
              text: '',
              oldUnit: HbA1cUnit.percentage,
              newUnit: HbA1cUnit.mmolMol,
            ),
            '',
          );
          expect(
            HbA1cCalculatorCoordinator.convertHbA1cDisplay(
              text: 'abc',
              oldUnit: HbA1cUnit.percentage,
              newUnit: HbA1cUnit.mmolMol,
            ),
            'abc',
          );
          expect(
            HbA1cCalculatorCoordinator.convertHbA1cDisplay(
              text: '0',
              oldUnit: HbA1cUnit.percentage,
              newUnit: HbA1cUnit.mmolMol,
            ),
            '0',
          );
        },
      );

      test('converts percentage to mmol/mol with formatting', () {
        expect(
          HbA1cCalculatorCoordinator.convertHbA1cDisplay(
            text: '7.0',
            oldUnit: HbA1cUnit.percentage,
            newUnit: HbA1cUnit.mmolMol,
          ),
          '53.0',
        );
        expect(
          HbA1cCalculatorCoordinator.convertHbA1cDisplay(
            text: '6,0',
            oldUnit: HbA1cUnit.percentage,
            newUnit: HbA1cUnit.mmolMol,
          ),
          '42.1',
        );
      });

      test('converts mmol/mol to percentage with formatting', () {
        expect(
          HbA1cCalculatorCoordinator.convertHbA1cDisplay(
            text: '53.0',
            oldUnit: HbA1cUnit.mmolMol,
            newUnit: HbA1cUnit.percentage,
          ),
          '7.00',
        );
      });

      test('returns original text when units are unchanged', () {
        expect(
          HbA1cCalculatorCoordinator.convertHbA1cDisplay(
            text: '6.5',
            oldUnit: HbA1cUnit.percentage,
            newUnit: HbA1cUnit.percentage,
          ),
          '6.5',
        );
      });
    });

    group('parseHbA1cPercentage', () {
      test('returns null for empty, whitespace, zero, or invalid text', () {
        expect(
          HbA1cCalculatorCoordinator.parseHbA1cPercentage(
            text: '',
            hba1cUnit: HbA1cUnit.percentage,
          ),
          isNull,
        );
        expect(
          HbA1cCalculatorCoordinator.parseHbA1cPercentage(
            text: '   ',
            hba1cUnit: HbA1cUnit.percentage,
          ),
          isNull,
        );
        expect(
          HbA1cCalculatorCoordinator.parseHbA1cPercentage(
            text: '0',
            hba1cUnit: HbA1cUnit.percentage,
          ),
          isNull,
        );
        expect(
          HbA1cCalculatorCoordinator.parseHbA1cPercentage(
            text: '-1.5',
            hba1cUnit: HbA1cUnit.percentage,
          ),
          isNull,
        );
        expect(
          HbA1cCalculatorCoordinator.parseHbA1cPercentage(
            text: 'xyz',
            hba1cUnit: HbA1cUnit.percentage,
          ),
          isNull,
        );
      });

      test('parses percentage directly supporting comma', () {
        expect(
          HbA1cCalculatorCoordinator.parseHbA1cPercentage(
            text: '6.5',
            hba1cUnit: HbA1cUnit.percentage,
          ),
          6.5,
        );
        expect(
          HbA1cCalculatorCoordinator.parseHbA1cPercentage(
            text: '6,8',
            hba1cUnit: HbA1cUnit.percentage,
          ),
          6.8,
        );
      });

      test('parses mmol/mol and converts to percentage', () {
        final parsed = HbA1cCalculatorCoordinator.parseHbA1cPercentage(
          text: '53.0',
          hba1cUnit: HbA1cUnit.mmolMol,
        );
        expect(parsed, closeTo(7.0, 0.05));
      });
    });
  });
}
