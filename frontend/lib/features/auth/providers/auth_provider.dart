import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

// Current logged-in user
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

// Auth state: null = loading, false = not logged in, true = logged in
final authStateProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  final loggedIn = await repo.isLoggedIn();
  if (loggedIn) {
    final user = await repo.getStoredUser();
    ref.read(currentUserProvider.notifier).state = user;
  }
  return loggedIn;
});

// Login state notifier
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final auth = await _repo.login(LoginRequest(email: email, password: password));
      _ref.read(currentUserProvider.notifier).state = auth.user;
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    state = const AsyncValue.loading();
    try {
      final auth = await _repo.register(request);
      _ref.read(currentUserProvider.notifier).state = auth.user;
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _ref.read(currentUserProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});
