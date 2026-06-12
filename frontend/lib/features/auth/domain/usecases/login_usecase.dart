import '../entities/user.dart';
import '../repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// LoginParams
// ---------------------------------------------------------------------------
class LoginParams {
  const LoginParams({
    required this.phone,
    required this.password,
  });

  final String phone;
  final String password;

  /// Trim and normalise phone before sending
  String get normalisedPhone {
    // Remove spaces and dashes; keep + prefix if present
    final clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    // Convert 0XXXXXXXXX -> +213XXXXXXXXX
    if (clean.startsWith('0') && clean.length == 10) {
      return '+213${clean.substring(1)}';
    }
    return clean;
  }
}

// ---------------------------------------------------------------------------
// LoginUseCase
// ---------------------------------------------------------------------------
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call(LoginParams params) async {
    if (params.phone.trim().isEmpty) {
      throw const AuthException('Phone number is required.');
    }
    if (params.password.trim().isEmpty) {
      throw const AuthException('Password is required.');
    }
    if (params.password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }

    return _repository.login(
      phone: params.normalisedPhone,
      password: params.password,
    );
  }
}
