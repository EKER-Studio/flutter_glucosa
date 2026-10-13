import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Section allowing users to import historical measurements from a CSV file.
class ExportCsvImportCard extends StatelessWidget {
  /// Whether a CSV import operation is currently in progress.
  final bool isImporting;

  /// Callback executed when user taps the select file button.
  final VoidCallback onImport;

  /// Creates an [ExportCsvImportCard].
  const ExportCsvImportCard({
    super.key,
    required this.isImporting,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Text(
          l10n.csvImportSection,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.csvImportSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isImporting ? null : onImport,
          icon: isImporting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              : const Icon(Icons.file_upload_outlined),
          label: Text(
            isImporting ? l10n.csvImportAnalyzing : l10n.csvImportPickFile,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
