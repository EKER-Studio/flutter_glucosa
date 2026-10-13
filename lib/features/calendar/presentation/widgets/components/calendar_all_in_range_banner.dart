import 'package:flutter/material.dart';

import '../../../../../core/presentation/theme/app_feedback_theme.dart';
import '../../../../../l10n/app_localizations.dart';

/// Banner indicating that all recorded readings for the selected date are within target range.
class CalendarAllInRangeBanner extends StatelessWidget {
  /// Creates a [CalendarAllInRangeBanner].
  const CalendarAllInRangeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final successBg = isDark
        ? AppFeedbackTheme.successBackgroundDark
        : AppFeedbackTheme.successBackgroundLight;
    final successFg = isDark
        ? AppFeedbackTheme.successForegroundDark
        : AppFeedbackTheme.successForegroundLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: successBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: successFg.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(Icons.check_circle_outline, color: successFg, size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.allReadingsInRangeBanner,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: successFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
