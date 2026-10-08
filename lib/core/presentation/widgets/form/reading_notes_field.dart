import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Reusable form text field for capturing optional user notes on health readings.
class ReadingNotesField extends StatelessWidget {
  /// Controller managing the notes text buffer.
  final TextEditingController controller;

  /// Creates a reading notes input field.
  const ReadingNotesField({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      maxLines: 3,
      maxLength: 500,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: l10n.notes,
        hintText: l10n.notesHint,
        prefixIcon: const Icon(Icons.notes_outlined),
        alignLabelWithHint: true,
      ),
    );
  }
}
