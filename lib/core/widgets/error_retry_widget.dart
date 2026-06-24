import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';

class ErrorRetryWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool slim;

  const ErrorRetryWidget({
    this.message,
    this.onRetry,
    this.slim = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final msg = message ?? 'Something went wrong. Please try again.';
    if (slim) {
      return Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.outfit(fontSize: 13),
              ),
            ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
