import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return ThemeNotifier(userId: userId);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final String? _userId;

  ThemeNotifier({String? userId})
      : _userId = userId,
        super(ThemeMode.light) {
    _loadTheme();
  }

  String get _key => _userId != null ? 'isDarkMode_$_userId' : 'isDarkMode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;
    if (mounted) state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    await prefs.setBool(_key, newMode == ThemeMode.dark);
  }
}
