/// Custom exception class for the application.
class AppException implements Exception {
  /// Unique identifier for the error type
  final String code;

  /// Human-readable error message
  final String message;

  const AppException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}
