import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Modal dialog helper for prompting deletion confirmation of recorded health readings.
class DeleteReadingDialog {
  const DeleteReadingDialog._();

  /// Displays the deletion confirmation alert dialog and returns whether confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
