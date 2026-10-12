/// Domain failure hierarchy for modeling domain and data layer error states.
///
/// Provides abstract and concrete failure representations that decouple UI and business
/// logic from technical database or framework-specific exception details.
sealed class Failure {
  const Failure(this.message);

  /// A human-readable description of the failure for logging and diagnostic purposes.
  final String message;
}

/// Failure originating from a local database or persistence operation.
class DatabaseFailure extends Failure {
  /// Creates a database failure instance with the underlying error [message].
  const DatabaseFailure(super.message);
}

/// Failure indicating that a requested resource was not found.
class NotFoundFailure extends Failure {
  /// Creates a not found failure instance with the underlying error [message].
  const NotFoundFailure(super.message);
}

/// Failure originating from a network or HTTP transport error.
class NetworkFailure extends Failure {
  /// Creates a network failure instance with the underlying error [message].
  const NetworkFailure(super.message);
}

/// Failure indicating that the user is not authenticated or the session expired.
class UnauthorizedFailure extends Failure {
  /// Creates an unauthorized failure instance with the underlying error [message].
  const UnauthorizedFailure(super.message);
}

/// Failure indicating that input did not pass validation.
class ValidationFailure extends Failure {
  /// Creates a validation failure instance with optional per-field validation error messages.
  const ValidationFailure(super.message, {this.fieldErrors = const {}});

  /// Per-field validation error messages keyed by field name.
  final Map<String, String> fieldErrors;
}

/// Failure originating from a Bluetooth Low Energy operation or device communication.
class BluetoothFailure extends Failure {
  /// Creates a Bluetooth failure instance with the underlying error [message].
  const BluetoothFailure(super.message);
}

/// Extension mapping domain [Failure] instances to localized or user-safe strings.
extension FailureUserMessage on Failure {
  /// A human-readable error message formatted for safe UI presentation.
  String get userMessage => message;
}
