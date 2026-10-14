import 'package:flutter/material.dart';
import 'package:flutter_glucosa/core/presentation/widgets/pill_segmented_control.dart';
import 'package:flutter_glucosa/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PillSegmentedControl', () {
    testWidgets('renders segments and highlights selection', (tester) async {
      var selected = 'a';
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => PillSegmentedControl<String>(
                segments: const [
                  PillSegment(value: 'a', label: 'Alpha'),
                  PillSegment(value: 'b', label: 'Beta'),
                ],
                selected: selected,
                onChanged: (value) => setState(() => selected = value),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();

      expect(selected, 'b');
    });

    testWidgets('tapping the selected segment emits nothing', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: PillSegmentedControl<String>(
              segments: const [
                PillSegment(value: 'a', label: 'Alpha'),
                PillSegment(value: 'b', label: 'Beta'),
              ],
              selected: 'a',
              onChanged: (_) => calls++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(calls, 0);
    });
  });
}
