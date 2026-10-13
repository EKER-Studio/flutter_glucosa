import 'package:flutter/material.dart';

import '../../../../core/domain/enums/glucose_range_preset.dart';
import '../../../../core/domain/enums/glucose_unit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/domain/entities/user_profile.dart';

/// Card presenting the user's active glucose target range and reference standard.
class OverviewTargetRangeCard extends StatelessWidget {
  /// The user profile containing target range settings.
  final UserProfile? profile;

  /// Creates an [OverviewTargetRangeCard].
  const OverviewTargetRangeCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final targetRange = profile?.targetRange;
    final presetName =
        targetRange?.preset.displayName ?? GlucoseRangePreset.ada.displayName;
    final minMgDl = targetRange?.minMgDl ?? 70;
    final maxMgDl = targetRange?.maxMgDl ?? 180;
    final unitName =
        profile?.preferredGlucoseUnit.displayName ??
        GlucoseUnit.mgDl.displayName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.track_changes_rounded,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    presetName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.targetRangeValue(
                      '$minMgDl',
                      '$maxMgDl',
                      unitName,
                      presetName,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
