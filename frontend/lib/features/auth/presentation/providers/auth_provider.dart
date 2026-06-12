import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

// ---------------------------------------------------------------------------
// AuthState – sealed class representing all auth states
// ---------------------------------------------------------------------------
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.harfidar.dz/api/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Add auth interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final storage = ref.read(_secureStorageRawProvider);
        final token = await storage.read(key: 'hd_access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Attempt token refresh
          try {
            final storage = ref.read(_secureStorageRawProvider);
            final refreshToken = await storage.read(key: 'hd_refresh_token');
            if (refreshToken != null && refreshToken.isNotEmpty) {
              final response = await dio.post<Map<String, dynamic>>(
                '/auth/refresh',
                data: {'refresh_token': refreshToken},
              );
              final newToken = response.data?['access_token'] as String?;
              if (newToken != null) {
                await storage.write(key: 'hd_access_token', value: newToken);
                // Retry original request
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final retryResp = await dio.fetch(opts);
                return handler.resolve(retryResp);
              }
            }
          } catch (_) {
            // Refresh failed – fall through to sign out
          }
          // Clear tokens and signal unauthenticated state
          final storage = ref.read(_secureStorageRawProvider);
          await storage.delete(key: 'hd_access_token');
          await storage.delete(key: 'hd_refresh_token');
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

final _secureStorageRawProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

// ---------------------------------------------------------------------------
// SecureStorage adapter that satisfies AuthLocalStorage
// ---------------------------------------------------------------------------

class _SecureStorageAdapter implements AuthLocalStorage {
  const _SecureStorageAdapter(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: 'hd_access_token', value: accessToken),
      _storage.write(key: 'hd_refresh_token', value: refreshToken),
    ]);
  }

  @override
  Future<String?> getAccessToken() => _storage.read(key: 'hd_access_token');

  @override
  Future<String?> getRefreshToken() => _storage.read(key: 'hd_refresh_token');

  @override
  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: 'hd_access_token'),
      _storage.delete(key: 'hd_refresh_token'),
      _storage.delete(key: 'hd_user_id'),
    ]);
  }

  @override
  Future<void> setUserId(String id) =>
      _storage.write(key: 'hd_user_id', value: id);
}

final authLocalStorageProvider = Provider<AuthLocalStorage>((ref) {
  return _SecureStorageAdapter(ref.watch(_secureStorageRawProvider));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localStorage: ref.watch(authLocalStorageProvider),
  );
});

// Use cases
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

// ---------------------------------------------------------------------------
// AuthNotifier
// ---------------------------------------------------------------------------
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required AuthRepository repository,
    required AuthLocalStorage localStorage,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _repository = repository,
        _localStorage = localStorage,
        super(const AuthInitial());

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final AuthRepository _repository;
  final AuthLocalStorage _localStorage;

  // ------------------------------------------------------------------
  // checkAuthStatus – called on app startup
  // ------------------------------------------------------------------
  Future<void> checkAuthStatus() async {
    state = const AuthLoading();
    try {
      final token = await _localStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = const AuthUnauthenticated();
        return;
      }
      final user = await _repository.getCurrentUser();
      state = AuthAuthenticated(user);
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  // ------------------------------------------------------------------
  // login
  // ------------------------------------------------------------------
  Future<void> login({required String phone, required String password}) async {
    state = const AuthLoading();
    try {
      final user = await _loginUseCase(LoginParams(phone: phone, password: password));
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  // ------------------------------------------------------------------
  // register
  // ------------------------------------------------------------------
  Future<void> register(RegisterParams params) async {
    state = const AuthLoading();
    try {
      final user = await _registerUseCase(params);
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  // ------------------------------------------------------------------
  // logout
  // ------------------------------------------------------------------
  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _logoutUseCase();
    } finally {
      state = const AuthUnauthenticated();
    }
  }

  // ------------------------------------------------------------------
  // forgotPassword
  // ------------------------------------------------------------------
  Future<bool> forgotPassword(String phone) async {
    try {
      await _repository.forgotPassword(phone);
      return true;
    } on AuthException catch (e) {
      state = AuthError(e.message);
      return false;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  // ------------------------------------------------------------------
  // clearError
  // ------------------------------------------------------------------
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  // ------------------------------------------------------------------
  // updateUser – update the user in the current state
  // ------------------------------------------------------------------
  void updateUser(User user) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(user);
    }
  }
}

// ---------------------------------------------------------------------------
// authStateProvider
// ---------------------------------------------------------------------------
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    repository: ref.watch(authRepositoryProvider),
    localStorage: ref.watch(authLocalStorageProvider),
  );
});

// Convenience selector providers
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState is AuthAuthenticated) return authState.user;
  return null;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider) is AuthAuthenticated;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider) is AuthLoading;
});
