import '../../../l10n/app_localizations.dart';
import '../../errors/failure.dart';

/// Presentation-layer extension that maps domain [Failure] instances to localized user messages.
extension LocalizedFailureUserMessage on Failure {
  /// Returns a localized user-friendly message for this failure.
  String toUserMessage(AppLocalizations l10n) => switch (this) {
    NotFoundFailure() => l10n.errorNotFound,
    DatabaseFailure() => l10n.errorDatabase,
    NetworkFailure() => l10n.errorNetwork,
    UnauthorizedFailure() => l10n.errorUnauthorized,
    ValidationFailure() => l10n.errorValidation,
    BluetoothFailure(:final message) =>
      message.isNotEmpty ? message : l10n.errorNetwork,
  };
}
