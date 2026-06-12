import '../repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// LogoutUseCase
// ---------------------------------------------------------------------------
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
