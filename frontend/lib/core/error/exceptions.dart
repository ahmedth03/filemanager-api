/// Base class for all application-specific exceptions.
///
/// All custom exceptions extend this class so callers can catch them with
/// a single `on AppException` clause when needed.
abstract class AppException implements Exception {
  const AppException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType(statusCode: $statusCode, message: $message)';
}

// ---------------------------------------------------------------------------
// Network exceptions
// ---------------------------------------------------------------------------

/// Thrown when there is no active network connection.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

/// Thrown when a request exceeds its configured timeout.
class TimeoutException extends AppException {
  const TimeoutException([
    super.message = 'The request timed out. Please try again.',
  ]);
}

// ---------------------------------------------------------------------------
// Server / API exceptions
// ---------------------------------------------------------------------------

/// Thrown when the server returns a non-2xx HTTP status code.
class ServerException extends AppException {
  const ServerException({
    required String message,
    required int statusCode,
    this.data,
  }) : super(message, statusCode);

  /// Raw response data from the server (may be null).
  final Object? data;
}

/// Thrown specifically for 400 Bad Request responses with validation errors.
class ValidationException extends AppException {
  const ValidationException({
    required String message,
    required this.errors,
  }) : super(message, 400);

  /// Map of field name → list of error messages.
  final Map<String, List<String>> errors;
}

/// Thrown when the server returns 401 Unauthorized or 403 Forbidden.
class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'You are not authorised to perform this action.',
    int statusCode = 401,
  ]) : super(statusCode);
}

/// Thrown when a requested resource could not be found (HTTP 404).
class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'The requested resource was not found.',
  ]) : super(404);
}

/// Thrown when the server is temporarily unavailable (HTTP 503).
class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException([
    super.message = 'The service is temporarily unavailable. Please try later.',
  ]) : super(503);
}

// ---------------------------------------------------------------------------
// Authentication exceptions
// ---------------------------------------------------------------------------

/// Thrown when a JWT token is expired or cannot be refreshed.
class TokenExpiredException extends AppException {
  const TokenExpiredException([
    super.message = 'Your session has expired. Please log in again.',
  ]) : super(401);
}

/// Thrown when an invalid or malformed token is detected.
class InvalidTokenException extends AppException {
  const InvalidTokenException([
    super.message = 'Invalid authentication token.',
  ]) : super(401);
}

// ---------------------------------------------------------------------------
// Cache / local storage exceptions
// ---------------------------------------------------------------------------

/// Thrown when reading from persistent storage fails.
class CacheReadException extends AppException {
  const CacheReadException([
    super.message = 'Failed to read data from local storage.',
  ]);
}

/// Thrown when writing to persistent storage fails.
class CacheWriteException extends AppException {
  const CacheWriteException([
    super.message = 'Failed to save data to local storage.',
  ]);
}

// ---------------------------------------------------------------------------
// Media exceptions
// ---------------------------------------------------------------------------

/// Thrown when an image or file upload fails.
class UploadException extends AppException {
  const UploadException([
    super.message = 'File upload failed. Please try again.',
  ]);
}

/// Thrown when a file exceeds the allowed size limit.
class FileSizeLimitException extends AppException {
  const FileSizeLimitException({
    super.message = 'The selected file exceeds the maximum allowed size.',
    this.maxSizeInMb = 10,
  });

  final int maxSizeInMb;

  @override
  String toString() =>
      'FileSizeLimitException: max ${maxSizeInMb}MB – $message';
}
