import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/auth/presentation/providers/pending_registration_provider.dart';
import 'package:ifind/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ifind/features/auth/presentation/screens/login_screen.dart';
import 'package:ifind/features/auth/presentation/screens/register_screen.dart';
import 'package:ifind/features/auth/presentation/screens/email_confirmation_screen.dart';
import 'package:ifind/features/auth/presentation/screens/registration_success_screen.dart';
import 'package:ifind/features/auth/presentation/screens/email_verified_screen.dart';
import 'package:ifind/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:ifind/features/auth/presentation/screens/reset_password_screen.dart';
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
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/features/business/presentation/screens/b2b_matches_screen.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/presentation/screens/shop_profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// Notifies GoRouter to re-evaluate redirects when auth/onboarding state changes,
// WITHOUT recreating the router (which would wipe widget state like _loginError).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<User?>>(authProvider, (_, __) => notifyListeners());
    ref.listen<bool>(onboardingCompleteProvider, (_, __) => notifyListeners());
    ref.listen<PendingRegistration?>(
        pendingRegistrationProvider, (_, __) => notifyListeners());
    ref.listen<AsyncValue<bool>>(
        ownerHasShopProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Watch only the resolved user — stable across loading/error states.
  // Router is only recreated on actual login/logout (role-based branches must update).
  final user = ref.watch(currentUserProvider);

  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      final currentUser = ref.read(currentUserProvider);
      final isAuth = currentUser != null;
      final loc = state.matchedLocation;
      final pendingRegistration = ref.read(pendingRegistrationProvider);
      final hasPendingRegistration = pendingRegistration != null;

      if (!isAuth &&
          hasPendingRegistration &&
          loc != '/confirmation' &&
          !loc.startsWith('/auth/callback')) {
        final email = Uri.encodeComponent(pendingRegistration.email);
        return '/confirmation?email=$email';
      }

      final isPublicAuthRoute = loc == '/login' ||
          loc == '/register' ||
          loc == '/onboarding' ||
          loc == '/forgot-password' ||
          loc == '/reset-password' ||
          loc.startsWith('/auth/callback') ||
          loc.startsWith('/confirmation') ||
          loc.startsWith('/registration-success') ||
          loc.startsWith('/email-verified');

      if (isPublicAuthRoute) {
        if (isAuth && (loc == '/login' || loc == '/register')) return '/';
        return null;
      }

      if (!isAuth) {
        final onboardingComplete = ref.read(onboardingCompleteProvider);
        if (!onboardingComplete) return '/onboarding';
        return '/login';
      }

      // Business owners must set up their shop before accessing anything else.
      if (currentUser.role == UserRole.businessOwner &&
          loc != '/setup-shop') {
        final shopStatus = ref.read(ownerHasShopProvider);
        if (!shopStatus.isLoading && shopStatus.valueOrNull == false) {
          return '/setup-shop';
        }
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
        path: '/b2b-matches',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const B2bMatchesScreen(),
      ),
      GoRoute(
        path: '/email-verified',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerifiedScreen(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // Main Application Shell - Role-based Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(
            navigationShell: navigationShell,
            user: user,
          );
        },
        branches: _buildBranches(user),
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
        builder: (context, state) =>
            PostNeedScreen(targetBusiness: state.extra as Business?),
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
      // Onboarding lock — business owners without a shop land here first
      GoRoute(
        path: '/setup-shop',
        builder: (context, state) =>
            const CreateBusinessScreen(isSetupMode: true),
      ),
      GoRoute(
        path: '/create-business',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CreateBusinessScreen(
            business: extra?['business'] as Business?,
          );
        },
      ),
      GoRoute(
        path: '/shop-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShopProfileScreen(),
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
        builder: (context, state) => ProfileScreen(
          initialEditing: state.extra == true,
        ),
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

List<StatefulShellBranch> _buildBranches(User? user) {
  final isBusinessOwner = user?.role == UserRole.businessOwner;

  // AI / For You branch — shared, always at index 2
  final forYouBranch = StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/for-you',
        builder: (context, state) => const AiSearchScreen(),
      ),
    ],
  );

  // Customer Branches: Home(0) | Discover(1) | ForYou(2) | Chats(3) | Profile(4)
  if (!isBusinessOwner) {
    return [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
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
      forYouBranch,
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
            path: '/profile',
            builder: (context, state) => ProfileScreen(
              initialEditing: state.extra == true,
            ),
          ),
        ],
      ),
    ];
  }

  // Business Owner Branches: Dashboard(0) | Discover(1) | ForYou(2) | Chats(3) | MyShop(4)
  return [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LeadsDashboardScreen(),
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
    forYouBranch,
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
  ];
}

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
      final isRecovery = Uri.base.toString().contains('type=recovery');
      await Supabase.instance.client.auth.getSessionFromUrl(_currentAuthUri());
      if (isRecovery) {
        if (mounted) context.go('/reset-password');
        return;
      }
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
    return const IFindLoadingPage(label: 'Confirming email…');
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => const IFindLoadingPage();
}
