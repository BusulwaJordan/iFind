import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/auth/presentation/providers/pending_registration_provider.dart';
import 'package:ifind/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ifind/features/auth/presentation/screens/login_screen.dart';
import 'package:ifind/features/auth/presentation/screens/register_screen.dart';
import 'package:ifind/features/auth/presentation/screens/email_confirmation_screen.dart';
import 'package:ifind/features/auth/presentation/screens/registration_success_screen.dart';
import 'package:ifind/features/auth/presentation/screens/email_verified_screen.dart';
import 'package:ifind/features/business/presentation/screens/create_business_screen.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';
import 'package:ifind/core/widgets/main_scaffold.dart';
import 'package:ifind/features/home/presentation/screens/home_screen.dart';
import 'package:ifind/features/business/presentation/screens/business_discovery_screen.dart';
import 'package:ifind/features/business/presentation/screens/my_shop_screen.dart';
import 'package:ifind/features/business/presentation/screens/leads_dashboard.dart';
import 'package:ifind/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:ifind/features/settings/presentation/screens/settings_screen.dart';
import 'package:ifind/features/needs/presentation/screens/post_need_screen.dart';
import 'package:ifind/features/business/presentation/screens/business_details_screen.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/recommendations/presentation/screens/ai_search_screen.dart';
import 'package:ifind/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ifind/features/favourites/presentation/screens/favourites_screen.dart';
import 'package:ifind/features/profile/presentation/screens/profile_screen.dart';
import 'package:ifind/features/help/presentation/screens/help_support_screen.dart';
import 'package:ifind/features/inquiries/presentation/screens/inquiries_screen.dart';
import 'package:ifind/app.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final onboardingComplete = ref.watch(onboardingCompleteProvider);
  final pendingRegistration = ref.watch(pendingRegistrationProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // Never redirect if currently loading — this prevents interference during registration
      if (authState.isLoading) return null;

      final isAuth = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      final hasPendingRegistration = pendingRegistration != null;

      if (!isAuth &&
          hasPendingRegistration &&
          loc != '/confirmation' &&
          !loc.startsWith('/auth/callback')) {
        final email = Uri.encodeComponent(pendingRegistration.email);
        return '/confirmation?email=$email';
      }

      // These routes are always public (no auth required) and should never be redirected
      final isPublicAuthRoute = loc == '/login' ||
          loc == '/register' ||
          loc == '/onboarding' ||
          loc.startsWith('/auth/callback') ||
          loc.startsWith('/confirmation') ||
          loc.startsWith('/registration-success') ||
          loc.startsWith('/email-verified');

      // If on any public auth route, do not redirect (allow screens to load normally)
      if (isPublicAuthRoute) {
        // Exception: if already authenticated, redirect from login/register to home
        if (isAuth && (loc == '/login' || loc == '/register')) {
          return '/';
        }
        return null;
      }

      if (!isAuth) {
        // Unauthenticated — send to onboarding first if not done yet
        if (!onboardingComplete) return '/onboarding';
        // Unauthenticated — send to login for protected routes
        return '/login';
      }

      return null;
    },
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/confirmation',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailConfirmationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),
      GoRoute(
        path: '/registration-success',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final req = state.uri.queryParameters['requiresConfirmation'];
          final requiresConfirmation = req == null ? true : req == 'true';
          return RegistrationSuccessScreen(
            email: email,
            requiresConfirmation: requiresConfirmation,
          );
        },
      ),
      GoRoute(
        path: '/email-verified',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerifiedScreen(email: email);
        },
      ),

      // Main Application Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) {
                  final user = authState.valueOrNull;
                  if (user == null) return const LoadingScreen();
                  return HomeScreen(user: user);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) {
                  final category = state.extra as BusinessCategory?;
                  return BusinessDiscoveryScreen(initialCategory: category);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-shop',
                builder: (context, state) => const MyShopScreen(),
              ),
            ],
          ),
        ],
      ),

      // Global Detail Routes (Not in Bottom Nav)
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/post-need',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PostNeedScreen(),
      ),
      GoRoute(
        path: '/leads-dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LeadsDashboardScreen(),
      ),
      GoRoute(
        path: '/ai-search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiSearchScreen(),
      ),
      GoRoute(
        path: '/business-details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final business = state.extra as Business;
          return BusinessDetailScreen(business: business);
        },
      ),
      GoRoute(
        path: '/create-business',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateBusinessScreen(),
      ),
      GoRoute(
        path: '/chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ChatRoomScreen(
            chat: extra['chat'] as Chat,
            otherPartyName: extra['otherPartyName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/favourites',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FavouritesScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/help',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/inquiries',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InquiriesScreen(),
      ),
    ],
  );
});

class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _finishAuth();
  }

  Future<void> _finishAuth() async {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(_currentAuthUri());
      await _waitForSession();
      await ref.read(authProvider.notifier).refreshCurrentUser();
      ref.read(pendingRegistrationProvider.notifier).state = null;
    } catch (_) {
      // The auth provider/router will keep the user on a safe public route.
    }

    if (mounted) context.go('/');
  }

  Future<void> _waitForSession() async {
    for (var attempt = 0; attempt < 12; attempt++) {
      if (Supabase.instance.client.auth.currentSession != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Uri _currentAuthUri() {
    final uri = Uri.base;
    if (uri.fragment.isEmpty || uri.fragment.startsWith('/')) return uri;

    return uri.replace(
      query: uri.query.isEmpty ? uri.fragment : '${uri.query}&${uri.fragment}',
      fragment: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Confirming your email...'),
          ],
        ),
      ),
    );
  }
}
