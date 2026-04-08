import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ifind/features/auth/presentation/screens/login_screen.dart';
import 'package:ifind/features/auth/presentation/screens/register_screen.dart';
import 'package:ifind/features/auth/presentation/screens/email_confirmation_screen.dart';
import 'package:ifind/features/business/presentation/screens/create_business_screen.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';
import 'package:ifind/core/widgets/main_scaffold.dart';
import 'package:ifind/features/home/presentation/screens/home_screen.dart';
import 'package:ifind/features/business/presentation/screens/business_discovery_screen.dart';
import 'package:ifind/features/business/presentation/screens/my_shop_screen.dart';
import 'package:ifind/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:ifind/features/settings/presentation/screens/settings_screen.dart';
import 'package:ifind/features/needs/presentation/screens/post_need_screen.dart';
import 'package:ifind/features/business/presentation/screens/business_details_screen.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/recommendations/presentation/screens/ai_search_screen.dart';
import 'package:ifind/app.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final onboardingComplete = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuth = authState.value != null;
      final loc = state.matchedLocation;

      final isPublicRoute = loc == '/login' ||
          loc == '/register' ||
          loc == '/onboarding' ||
          loc.startsWith('/confirmation');

      if (!isAuth) {
        if (!onboardingComplete && loc != '/onboarding') return '/onboarding';
        if (onboardingComplete && !isPublicRoute) return '/login';
      } else {
        if (isPublicRoute) return '/';
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
                  final user = authState.value;
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
        path: '/post-need',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PostNeedScreen(),
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
    ],
  );
});
