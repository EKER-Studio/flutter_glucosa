import '../../../../core/domain/enums/meal_context.dart';
import '../../../../core/domain/value_objects/glucose_target_range.dart';
import '../../../glucose/domain/entities/glucose_reading.dart';
import '../entities/milestone.dart';

/// Pure domain service evaluating user habit achievements and clinical milestones from glucose readings.
class MilestoneCalculator {
  const MilestoneCalculator._();

  /// Evaluates all defined [MilestoneType] milestones against historical [readings] and [targetRange].
  static List<Milestone> evaluate({
    required List<GlucoseReading> readings,
    GlucoseTargetRange targetRange = const GlucoseTargetRange.ada(),
  }) {
    return evaluateAll(readings: readings, targetRange: targetRange);
  }

  /// Evaluates all defined [MilestoneType] milestones against historical [readings] and [targetRange].
  static List<Milestone> evaluateAll({
    required List<GlucoseReading> readings,
    GlucoseTargetRange targetRange = const GlucoseTargetRange.ada(),
  }) {
    if (readings.isEmpty) {
      return MilestoneType.values
          .map(
            (type) => Milestone(type: type, isUnlocked: false, progress: 0.0),
          )
          .toList();
    }

    final sorted = readings.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final uniqueDates =
        sorted
            .map(
              (r) => DateTime(
                r.createdAt.year,
                r.createdAt.month,
                r.createdAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort();

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? prevDate;
    DateTime? streak7Date;
    DateTime? streak30Date;
    DateTime? streak100Date;
    DateTime? streak365Date;
    DateTime? comebackDate;
    bool hasComeback = false;

    for (final date in uniqueDates) {
      if (prevDate == null) {
        currentStreak = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          if (diff > 14) {
            hasComeback = true;
            comebackDate ??= date;
          }
          currentStreak = 1;
        }
      }
      prevDate = date;

      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }
      if (currentStreak >= 7 && streak7Date == null) streak7Date = date;
      if (currentStreak >= 30 && streak30Date == null) streak30Date = date;
      if (currentStreak >= 100 && streak100Date == null) streak100Date = date;
      if (currentStreak >= 365 && streak365Date == null) streak365Date = date;
    }

    // Routines & Special Days
    int fastingCount = 0;
    DateTime? fastingDate;
    int postMealCount = 0;
    DateTime? postMealDate;
    DateTime? earlyBirdDate;
    DateTime? nightOwlDate;
    DateTime? newYearDate;
    DateTime? yearEndDate;

    final Set<String> weekendSaturdaysWithSundays = {};
    final Map<String, Set<int>> weekendDaysLogged = {}; // key: "YYYY-W"

    for (final r in sorted) {
      if (r.mealContext == MealContext.fasting) {
        fastingCount++;
        if (fastingCount == 10) fastingDate = r.createdAt;
      } else if (r.mealContext == MealContext.afterBreakfast ||
          r.mealContext == MealContext.afterLunch ||
          r.mealContext == MealContext.afterDinner) {
        postMealCount++;
        if (postMealCount == 10) postMealDate = r.createdAt;
      }

      if (r.createdAt.hour < 7 && earlyBirdDate == null) {
        earlyBirdDate = r.createdAt;
      }
      if (r.createdAt.hour >= 23 && nightOwlDate == null) {
        nightOwlDate = r.createdAt;
      }
      if (r.createdAt.month == 1 &&
          r.createdAt.day == 1 &&
          newYearDate == null) {
        newYearDate = r.createdAt;
      }
      if (r.createdAt.month == 12 &&
          r.createdAt.day == 31 &&
          yearEndDate == null) {
        yearEndDate = r.createdAt;
      }

      // Check weekend warrior (Saturday is 6, Sunday is 7)
      if (r.createdAt.weekday == DateTime.saturday ||
          r.createdAt.weekday == DateTime.sunday) {
        // Find the Monday of this week to group weekend
        final monday = r.createdAt.subtract(
          Duration(days: r.createdAt.weekday - 1),
        );
        final key = '${monday.year}-${monday.month}-${monday.day}';
        final weekendDays = weekendDaysLogged.putIfAbsent(key, () => <int>{});
        weekendDays.add(r.createdAt.weekday);
        if (weekendDays.contains(DateTime.saturday) &&
            weekendDays.contains(DateTime.sunday)) {
          weekendSaturdaysWithSundays.add(key);
        }
      }
    }

    // Clinical Time-in-Range (TIR) Milestones
    bool tirWeekUnlocked = false;
    DateTime? tirWeekDate;
    double bestTirWeekProgress = 0.0;

    bool tirMonthUnlocked = false;
    DateTime? tirMonthDate;
    double bestTirMonthProgress = 0.0;

    for (var i = 0; i < sorted.length; i++) {
      final currentReading = sorted[i];
      final weekStart = currentReading.createdAt.subtract(
        const Duration(days: 7),
      );
      final monthStart = currentReading.createdAt.subtract(
        const Duration(days: 30),
      );

      final weekWindow = sorted
          .where(
            (r) =>
                !r.createdAt.isBefore(weekStart) &&
                !r.createdAt.isAfter(currentReading.createdAt),
          )
          .toList();

      if (weekWindow.length >= 14) {
        final inRange = weekWindow
            .where((r) => targetRange.isInRange(r.readingMgDl))
            .length;
        final tir = inRange / weekWindow.length;
        if (tir > bestTirWeekProgress) bestTirWeekProgress = tir;
        if (tir >= 0.70 && !tirWeekUnlocked) {
          tirWeekUnlocked = true;
          tirWeekDate = currentReading.createdAt;
        }
      }

      final monthWindow = sorted
          .where(
            (r) =>
                !r.createdAt.isBefore(monthStart) &&
                !r.createdAt.isAfter(currentReading.createdAt),
          )
          .toList();

      if (monthWindow.length >= 50) {
        final inRange = monthWindow
            .where((r) => targetRange.isInRange(r.readingMgDl))
            .length;
        final tir = inRange / monthWindow.length;
        if (tir > bestTirMonthProgress) bestTirMonthProgress = tir;
        if (tir >= 0.70 && !tirMonthUnlocked) {
          tirMonthUnlocked = true;
          tirMonthDate = currentReading.createdAt;
        }
      }
    }

    return MilestoneType.values.map((type) {
      return switch (type) {
        MilestoneType.firstReading => Milestone(
          type: type,
          isUnlocked: true,
          progress: 1.0,
          unlockedDate: sorted.first.createdAt,
        ),
        MilestoneType.streak7 => Milestone(
          type: type,
          isUnlocked: maxStreak >= 7,
          progress: (maxStreak / 7.0).clamp(0.0, 1.0),
          unlockedDate: streak7Date,
        ),
        MilestoneType.streak30 => Milestone(
          type: type,
          isUnlocked: maxStreak >= 30,
          progress: (maxStreak / 30.0).clamp(0.0, 1.0),
          unlockedDate: streak30Date,
        ),
        MilestoneType.streak100 => Milestone(
          type: type,
          isUnlocked: maxStreak >= 100,
          progress: (maxStreak / 100.0).clamp(0.0, 1.0),
          unlockedDate: streak100Date,
        ),
        MilestoneType.streak365 => Milestone(
          type: type,
          isUnlocked: maxStreak >= 365,
          progress: (maxStreak / 365.0).clamp(0.0, 1.0),
          unlockedDate: streak365Date,
        ),
        MilestoneType.comeback => Milestone(
          type: type,
          isUnlocked: hasComeback,
          progress: hasComeback ? 1.0 : 0.0,
          unlockedDate: comebackDate,
        ),
        MilestoneType.targetTirWeek => Milestone(
          type: type,
          isUnlocked: tirWeekUnlocked,
          progress: (bestTirWeekProgress / 0.70).clamp(0.0, 1.0),
          unlockedDate: tirWeekDate,
        ),
        MilestoneType.targetTirMonth => Milestone(
          type: type,
          isUnlocked: tirMonthUnlocked,
          progress: (bestTirMonthProgress / 0.70).clamp(0.0, 1.0),
          unlockedDate: tirMonthDate,
        ),
        MilestoneType.fastingChampion => Milestone(
          type: type,
          isUnlocked: fastingCount >= 10,
          progress: (fastingCount / 10.0).clamp(0.0, 1.0),
          unlockedDate: fastingDate,
        ),
        MilestoneType.postMealMaster => Milestone(
          type: type,
          isUnlocked: postMealCount >= 10,
          progress: (postMealCount / 10.0).clamp(0.0, 1.0),
          unlockedDate: postMealDate,
        ),
        MilestoneType.earlyBird => Milestone(
          type: type,
          isUnlocked: earlyBirdDate != null,
          progress: earlyBirdDate != null ? 1.0 : 0.0,
          unlockedDate: earlyBirdDate,
        ),
        MilestoneType.nightOwl => Milestone(
          type: type,
          isUnlocked: nightOwlDate != null,
          progress: nightOwlDate != null ? 1.0 : 0.0,
          unlockedDate: nightOwlDate,
        ),
        MilestoneType.weekendWarrior => Milestone(
          type: type,
          isUnlocked: weekendSaturdaysWithSundays.isNotEmpty,
          progress: weekendSaturdaysWithSundays.isNotEmpty ? 1.0 : 0.0,
          unlockedDate: weekendSaturdaysWithSundays.isNotEmpty
              ? sorted
                    .firstWhere((r) => r.createdAt.weekday == DateTime.sunday)
                    .createdAt
              : null,
        ),
        MilestoneType.newYear => Milestone(
          type: type,
          isUnlocked: newYearDate != null,
          progress: newYearDate != null ? 1.0 : 0.0,
          unlockedDate: newYearDate,
        ),
        MilestoneType.yearEnd => Milestone(
          type: type,
          isUnlocked: yearEndDate != null,
          progress: yearEndDate != null ? 1.0 : 0.0,
          unlockedDate: yearEndDate,
        ),
      };
    }).toList();
  }
}
