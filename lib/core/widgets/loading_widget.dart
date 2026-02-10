import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ifind/core/constants/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  final double size;
  const LoadingWidget({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primaryGreen,
                size: 32,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5))
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: 800.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: const Offset(1.2, 1.2),
              end: const Offset(0.8, 0.8),
              duration: 800.ms,
              curve: Curves.easeInOut,
            ),
            const SizedBox(height: 16),
            const Text(
              'Thinking...',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .fadeIn(duration: 1000.ms)
             .then()
             .fadeOut(duration: 1000.ms),
          ],
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.5));
  }
}
