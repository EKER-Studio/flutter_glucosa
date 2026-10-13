import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/app_localizations.dart';

/// Card displayed on the dashboard when no glucose measurements have been recorded yet.
class OverviewEmptyReadingCard extends StatelessWidget {
  /// Creates an [OverviewEmptyReadingCard].
  const OverviewEmptyReadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noReadingsYet,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.addGlucoseReading),
              onPressed: () => context.push(AppRoute.addGlucose.path),
            ),
          ],
        ),
      ),
    );
  }
}
