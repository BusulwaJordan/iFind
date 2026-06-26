import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';

class OwnerAvatar extends ConsumerWidget {
  final String ownerId;
  final double radius;
  const OwnerAvatar({super.key, required this.ownerId, this.radius = 16});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerAsync = ref.watch(userProfileProvider(ownerId));
    final avatarUrl = ownerAsync.valueOrNull?.avatarUrl;
    final initials = ownerAsync.valueOrNull?.fullName.isNotEmpty == true
        ? ownerAsync.value!.fullName[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryGreen,
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Text(
                initials,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold),
              )
            : null,
      ),
    );
  }
}
