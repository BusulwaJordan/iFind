import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/theme/app_theme.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/auth/presentation/screens/email_confirmation_screen.dart';
import 'package:ifind/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ifind/features/auth/presentation/screens/login_screen.dart';
import 'package:ifind/features/auth/presentation/screens/register_screen.dart';
import 'package:ifind/features/business/presentation/screens/create_business_screen.dart';
import 'package:ifind/features/home/presentation/screens/home_screen.dart';
import 'package:ifind/core/widgets/main_scaffold.dart';
import 'package:ifind/core/widgets/loading_widget.dart';

/// Main App Entry Point
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'iFind',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/confirmation': (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return EmailConfirmationScreen(email: email);
        },
        '/create-business': (context) => const CreateBusinessScreen(),
      },
    );
  }
}

/// Auth Wrapper - Routes to appropriate screen based on auth state
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final onboardingComplete = ref.watch(onboardingCompleteProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return onboardingComplete ? const LoginScreen() : const OnboardingScreen();
        }
        return const MainScaffold();
      },
      loading: () => const LoadingScreen(),
      error: (error, stack) => ErrorScreen(message: error.toString()),
    );
  }
}

/// Loading Screen
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LoadingWidget(),
    );
  }
}

/// Error Screen
class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $message',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Old HomeScreen removed. Imported from features/home/presentation/screens/home_screen.dart
