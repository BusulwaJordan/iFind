import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:ifind/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ifind/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/auth/domain/repositories/auth_repository.dart';
import 'package:ifind/features/auth/domain/usecases/get_current_user.dart';
import 'package:ifind/features/auth/domain/usecases/login.dart';
import 'package:ifind/features/auth/domain/usecases/logout.dart';
import 'package:ifind/features/auth/domain/usecases/register.dart';

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Auth remote data source provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

/// Use case providers
final loginUseCaseProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<Register>((ref) {
  return Register(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<Logout>((ref) {
  return Logout(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUser>((ref) {
  return GetCurrentUser(ref.watch(authRepositoryProvider));
});

/// Shared Preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Should be overridden in main
});

/// Onboarding state provider
final onboardingCompleteProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'onboarding_complete';

  OnboardingNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_key, true);
    state = true;
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository authRepository;
  final Login loginUseCase;
  final Register registerUseCase;
  final Logout logoutUseCase;
  final GetCurrentUser getCurrentUserUseCase;

  AuthNotifier({
    required this.authRepository,
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      debugPrint('Found existing Supabase session for: ${session.user.id}');
      final result = await getCurrentUserUseCase();
      result.fold(
        (failure) {
          // Network issue — don't log the user out, keep them authenticated
          // using basic info from the JWT session token. They can still use the app.
          debugPrint('Profile fetch failed (likely network issue). Keeping session alive.');
          final u = session.user;
          final metadata = u.userMetadata ?? {};
          final roleStr = metadata['role'] as String? ?? 'customer';
          final parsedRole = roleStr == 'business_owner'
              ? UserRole.businessOwner
              : (roleStr == 'manager' ? UserRole.manager : UserRole.customer);
          state = AsyncValue.data(User(
            id: u.id,
            email: u.email ?? '',
            fullName: metadata['full_name'] as String? ?? 'iFind User',
            role: parsedRole,
            phone: metadata['phone'] as String?,
            createdAt: DateTime.tryParse(u.createdAt) ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        },
        (user) => state = AsyncValue.data(user),
      );
    } else {
      state = const AsyncValue.data(null);
    }

    // Listen to auth state changes for real-time updates (Google OAuth callback lands here)
    authRepository.authStateChanges.listen((user) {
      debugPrint('Auth state changed. User: ${user?.id}');
      state = AsyncValue.data(user);
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await loginUseCase(email: email, password: password);
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await authRepository.loginWithGoogle();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) {
        // Redirection handled by Supabase OAuth. 
        // We wait for onAuthStateChange to bring the user back.
        // It's possible the user cancels, so we set a timeout or rely on GoRouter.
        // For now, let's reset state to null to clear loading spinner.
        state = const AsyncValue.data(null);
      },
    );
  }

  Future<User?> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    final result = await registerUseCase(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (user) {
        // If Supabase confirms the user immediately (no email verification), set state
        // Let's use the actual client session
        final hasSession = Supabase.instance.client.auth.currentSession != null;
        
        if (hasSession) {
          state = AsyncValue.data(user);
        } else {
          // Stay as null/unauthenticated state so screen can show confirmation
          state = const AsyncValue.data(null);
        }
        return user;
      },
    );
  }

  Future<void> logout() async {
    final result = await logoutUseCase();
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (user) => state = const AsyncValue.data(null),
    );
  }
}

/// Auth state provider
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(
    authRepository: ref.watch(authRepositoryProvider),
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
  );
});

/// Current user provider (convenience)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});

/// Fetch user profile by ID
final userProfileProvider = FutureProvider.family<User, String>((ref, userId) async {
  final repo = ref.watch(authRepositoryProvider);
  final result = await repo.getUserById(userId);
  return result.fold(
    (failure) => throw failure.message,
    (user) => user,
  );
});
