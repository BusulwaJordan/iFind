import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/home/presentation/screens/home_screen.dart';
import 'package:ifind/features/business/presentation/screens/business_discovery_screen.dart';
import 'package:ifind/features/business/presentation/screens/my_shop_screen.dart';
import 'package:ifind/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final screens = [
      HomeScreen(user: user),
      const BusinessDiscoveryScreen(),
      const ChatListScreen(),
      const MyShopScreen(),
    ];

    return Scaffold(
      extendBody: true, // Allows content to be seen behind the floating nav
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.explore_rounded, 'Discover'),
                _buildNavItem(2, Icons.chat_bubble_rounded, 'Chat'),
                _buildNavItem(3, Icons.business_center_rounded, 'My Shop'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.primaryGreen : Colors.grey[400];

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected ? [
                BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.05), blurRadius: 10)
              ] : null,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              height: 3,
              width: 12,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
