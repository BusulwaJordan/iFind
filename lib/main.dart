import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/constants/api_constants.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/services/deep_link_service.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/core/providers/theme_provider.dart';
import 'package:ifind/core/router/app_router.dart'; // Import the router

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env", isOptional: true);

      final prefs = await SharedPreferences.getInstance();

      await Supabase.initialize(
        url: ApiConstants.supabaseUrl,
        anonKey: ApiConstants.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      await DeepLinkService().initialize();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        if (kReleaseMode) debugPrint('[FlutterError] ${details.exception}');
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('[PlatformError] $error\n$stack');
        return true;
      };

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) => debugPrint('[ZoneError] $error\n$stack'),
  );
}

ThemeData _buildTheme(Brightness brightness) {
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.primaryGreen,
    brightness: brightness,
  );
  const clickStyle = ButtonStyle(
    mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: base.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: base.surface,
      foregroundColor: base.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: base.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    listTileTheme: ListTileThemeData(
      tileColor: base.surfaceContainerLow,
      mouseCursor: WidgetStateMouseCursor.clickable,
    ),
    dividerTheme: DividerThemeData(color: base.outlineVariant),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: base.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: const ElevatedButtonThemeData(style: clickStyle),
    textButtonTheme: const TextButtonThemeData(style: clickStyle),
    outlinedButtonTheme: const OutlinedButtonThemeData(style: clickStyle),
    iconButtonTheme: const IconButtonThemeData(style: clickStyle),
  );
}

// Override MyApp to use theme provider and router
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider); // Get the router from your provider

    return MaterialApp.router(
      title: 'iFind',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}