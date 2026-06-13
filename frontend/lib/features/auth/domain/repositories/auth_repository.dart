import '../entities/user.dart';

// ---------------------------------------------------------------------------
// Custom exceptions used throughout the auth feature
// ---------------------------------------------------------------------------

class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthException: $message${code != null ? ' (code: $code)' : ''}';
}

class UnauthorizedException extends AuthException {
  const UnauthorizedException([String message = 'Unauthorized. Please log in again.'])
      : super(message, code: '401');
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException(
      [String message = 'Invalid phone number or password.'])
      : super(message, code: 'INVALID_CREDENTIALS');
}

class PhoneAlreadyExistsException extends AuthException {
  const PhoneAlreadyExistsException(
      [String message = 'An account with this phone number already exists.'])
      : super(message, code: 'PHONE_EXISTS');
}

class NetworkException extends AuthException {
  const NetworkException([String message = 'Network error. Please check your connection.'])
      : super(message, code: 'NETWORK_ERROR');
}

class ServerException extends AuthException {
  const ServerException([String message = 'Server error. Please try again later.'])
      : super(message, code: 'SERVER_ERROR');
}

// ---------------------------------------------------------------------------
// AuthRepository – abstract interface
// ---------------------------------------------------------------------------
abstract interface class AuthRepository {
  /// Authenticate with phone and password. Returns the authenticated [User].
  Future<User> login({
    required String phone,
    required String password,
  });

  /// Register a new account. Returns the newly created [User].
  Future<User> register({
    required String name,
    required String phone,
    required String password,
    required UserType userType,
    String? wilaya,
  });

  /// Sign the current user out and invalidate the token.
  Future<void> logout();

  /// Fetch the currently authenticated user from the server.
  Future<User> getCurrentUser();

  /// Refresh the access token using the stored refresh token.
  /// Returns the new access token string.
  Future<String> refreshToken();

  /// Initiate a forgot-password flow for the given [phone].
  Future<void> forgotPassword(String phone);

  /// Verify OTP code sent to phone. Returns new token on success.
  Future<String> verifyOtp({
    required String phone,
    required String otp,
  });

  /// Reset password using a verified OTP token.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Update profile of the authenticated user.
  Future<User> updateProfile({
    String? name,
    String? email,
    String? bio,
    String? wilaya,
    String? avatarPath,
  });
}
