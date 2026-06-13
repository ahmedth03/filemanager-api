import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Sealed Failure hierarchy using Freezed.
///
/// Every repository method returns `Either<Failure, T>` so callers
/// can handle failures in a type-safe, exhaustive way:
///
/// ```dart
/// result.fold(
///   (failure) => failure.when(
///     network: (msg) => showToast('No internet'),
///     server: (code, msg) => showToast('Server error $code: $msg'),
///     cache: (msg) => showToast('Cache error'),
///     auth: (msg) => router.go('/login'),
///     validation: (errors) => showFieldErrors(errors),
///     unknown: (msg) => showToast('Unknown error'),
///   ),
///   (data) => handleData(data),
/// );
/// ```
@freezed
sealed class Failure with _$Failure {
  // ── Network ────────────────────────────────────────────────────────────────
  /// Thrown when there is no internet connection or the request timed out.
  const factory Failure.network({
    @Default('No internet connection. Please check your network settings.')
    String message,
  }) = NetworkFailure;

  // ── Server ─────────────────────────────────────────────────────────────────
  /// Thrown when the server returns an error response (4xx / 5xx).
  const factory Failure.server({
    required int statusCode,
    @Default('An unexpected server error occurred.') String message,
    Object? data,
  }) = ServerFailure;

  // ── Cache ──────────────────────────────────────────────────────────────────
  /// Thrown when reading from or writing to local storage fails.
  const factory Failure.cache({
    @Default('Failed to read or write local data.') String message,
  }) = CacheFailure;

  // ── Auth ───────────────────────────────────────────────────────────────────
  /// Thrown when the user is not authenticated or the token has expired.
  const factory Failure.auth({
    @Default('Authentication required. Please log in.') String message,
  }) = AuthFailure;

  // ── Validation ─────────────────────────────────────────────────────────────
  /// Thrown when request data fails server-side validation.
  ///
  /// [errors] maps field names to a list of error messages, e.g.:
  /// `{'phone': ['Invalid Algerian phone number']}`.
  const factory Failure.validation({
    @Default('Please fix the errors and try again.') String message,
    @Default(<String, List<String>>{}) Map<String, List<String>> errors,
  }) = ValidationFailure;

  // ── Unknown ────────────────────────────────────────────────────────────────
  /// Catch-all for failures that do not fit any of the above categories.
  const factory Failure.unknown({
    @Default('An unexpected error occurred.') String message,
    Object? exception,
  }) = UnknownFailure;
}

// ---------------------------------------------------------------------------
// Convenience extension
// ---------------------------------------------------------------------------

extension FailureX on Failure {
  /// Human-readable description (suitable for error banners / toasts).
  String get displayMessage => when(
        network: (msg) => msg,
        server: (code, msg, _) => '($code) $msg',
        cache: (msg) => msg,
        auth: (msg) => msg,
        validation: (msg, _) => msg,
        unknown: (msg, _) => msg,
      );

  /// Returns true only for [NetworkFailure].
  bool get isNetworkFailure => this is NetworkFailure;

  /// Returns true only for [AuthFailure].
  bool get isAuthFailure => this is AuthFailure;
}
