import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/theme/app_theme.dart';
import 'package:ifind/core/router/app_router.dart';
import 'package:ifind/core/widgets/startup_location_prompt.dart';
import 'package:ifind/core/widgets/startup_update_prompt.dart';

/// Main App Entry Point
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'iFind',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
      builder: (context, child) => StartupUpdatePrompt(
        child: StartupLocationPrompt(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Splash / Loading Screen shown while auth resolves
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 1),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.rocket_launch_rounded,
                      size: 64,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
