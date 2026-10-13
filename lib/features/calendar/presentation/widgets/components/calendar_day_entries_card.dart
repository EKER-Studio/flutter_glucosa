import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/domain/enums/glucose_status.dart';
import '../../../../../core/domain/enums/glucose_unit.dart';
import '../../../../../core/domain/utils/glucose_status_resolver.dart';
import '../../../../../core/domain/value_objects/glucose_target_range.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../glucose/domain/entities/glucose_reading.dart';
import 'calendar_all_in_range_banner.dart';
import 'calendar_day_reading_card.dart';

/// Lists recorded glucose readings for the selected date with status indicators, edit/delete actions, and a banner.
class CalendarDayEntriesCard extends StatelessWidget {
  /// The selected calendar date.
  final DateTime selectedDate;

  /// The list of [GlucoseReading] entities for this day.
  final List<GlucoseReading> readings;

  /// The active clinical target range.
  final GlucoseTargetRange targetRange;

  /// Preferred glucose measurement unit.
  final GlucoseUnit preferredUnit;

  /// Creates a [CalendarDayEntriesCard].
  const CalendarDayEntriesCard({
    super.key,
    required this.selectedDate,
    required this.readings,
    this.targetRange = const GlucoseTargetRange.ada(),
    this.preferredUnit = GlucoseUnit.mgDl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final statuses = readings
        .map(
          (r) => GlucoseStatusResolver.resolve(
            readingMgDl: r.readingMgDl,
            targetRange: targetRange,
          ),
        )
        .toList();

    final allInRange =
        readings.isNotEmpty &&
        statuses.every((s) => s == GlucoseStatus.inRange);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (allInRange) ...[
          const CalendarAllInRangeBanner(),
          const SizedBox(height: 16),
        ],
        ListView.separated(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: readings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return CalendarDayReadingCard(
              reading: readings[index],
              status: statuses[index],
              preferredUnit: preferredUnit,
            );
          },
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => context.push(AppRoute.addGlucose.path),
          icon: const Icon(Icons.add),
          label: Text(l10n.addAnotherReading),
        ),
      ],
    );
  }
}
