import '../entities/user.dart';
import '../repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// RegisterParams
// ---------------------------------------------------------------------------
class RegisterParams {
  const RegisterParams({
    required this.name,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.userType,
    this.wilaya,
    this.acceptedTerms = false,
  });

  final String name;
  final String phone;
  final String password;
  final String confirmPassword;
  final UserType userType;
  final String? wilaya;
  final bool acceptedTerms;

  String get normalisedPhone {
    final clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.startsWith('0') && clean.length == 10) {
      return '+213${clean.substring(1)}';
    }
    return clean;
  }
}

// ---------------------------------------------------------------------------
// RegisterUseCase
// ---------------------------------------------------------------------------
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call(RegisterParams params) async {
    // Validate inputs before hitting the network
    _validate(params);

    return _repository.register(
      name: params.name.trim(),
      phone: params.normalisedPhone,
      password: params.password,
      userType: params.userType,
      wilaya: params.wilaya,
    );
  }

  void _validate(RegisterParams p) {
    if (p.name.trim().isEmpty) {
      throw const AuthException('Full name is required.');
    }
    if (p.name.trim().length < 2) {
      throw const AuthException('Name must be at least 2 characters.');
    }
    if (p.phone.trim().isEmpty) {
      throw const AuthException('Phone number is required.');
    }
    final phoneClean = p.phone.replaceAll(RegExp(r'[\s\-]'), '');
    final localFormat = RegExp(r'^(05|06|07)\d{8}$');
    final intlFormat = RegExp(r'^\+2135[0-9]\d{8}$|^\+2136[0-9]\d{8}$|^\+2137[0-9]\d{8}$');
    if (!localFormat.hasMatch(phoneClean) && !intlFormat.hasMatch(phoneClean)) {
      throw const AuthException('Please enter a valid Algerian phone number.');
    }
    if (p.password.isEmpty) {
      throw const AuthException('Password is required.');
    }
    if (p.password.length < 8) {
      throw const AuthException('Password must be at least 8 characters.');
    }
    if (p.password != p.confirmPassword) {
      throw const AuthException('Passwords do not match.');
    }
    if (!p.acceptedTerms) {
      throw const AuthException('You must accept the terms and conditions.');
    }
  }
}
