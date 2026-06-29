import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:ifind/features/auth/domain/entities/user.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  Uint8List? _imageBytes;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _imageUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final ext = picked.mimeType?.split('/').last.toLowerCase() ??
        (picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : 'jpg');

    // Show preview immediately
    setState(() {
      _imageBytes = bytes;
      _isUploadingPhoto = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final supabase = Supabase.instance.client;
      final path = 'avatars/${user.id}.$ext';

      await supabase.storage.from('profile_images').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
      );

      final newUrl =
          '${supabase.storage.from('profile_images').getPublicUrl(path)}'
          '?v=${DateTime.now().millisecondsSinceEpoch}';

      // Update both the users table and auth metadata so refreshCurrentUser
      // picks up the new URL regardless of which source it reads from.
      await supabase.from('users').update({
        'avatar_url': newUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      await supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': newUrl}),
      );

      await ref.read(authProvider.notifier).refreshCurrentUser();

      // Refresh OwnerAvatar widgets that cache this user's profile.
      ref.invalidate(userProfileProvider(user.id));

      setState(() => _imageUrl = newUrl);

      if (mounted) {
        AppToast.show(context, 'Profile photo updated', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Photo upload failed: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        AppToast.show(context, 'You are not signed in', type: ToastType.error);
        return;
      }

      // Photo is already uploaded in _pickImage — just save name/phone here.
      final supabase = Supabase.instance.client;
      final phone = _phoneController.text.trim();
      await supabase.from('users').update({
        'full_name': _nameController.text.trim(),
        'phone': phone.isEmpty ? null : phone,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id).select().single();

      await supabase.auth.updateUser(
        UserAttributes(data: {
          'full_name': _nameController.text.trim(),
        }),
      );

      await ref.read(authProvider.notifier).refreshCurrentUser();
      if (!mounted) return;
      AppToast.show(context, 'Profile updated', type: ToastType.success);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.show(context, 'Error: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              _isLoading ? 'Saving...' : 'Save',
              style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickImage,
                child: MouseRegion(
                  cursor: _isUploadingPhoto
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: _buildAvatar(user),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: user?.email ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(User? user) {
    final effectiveUrl = _imageUrl ?? user?.avatarUrl;
    final initial = user?.fullName.isNotEmpty == true
        ? user!.fullName[0].toUpperCase()
        : 'U';

    Widget avatarChild;
    if (_imageBytes != null) {
      avatarChild = Image.memory(
        _imageBytes!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    } else if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      avatarChild = Image.network(
        effectiveUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Text(initial,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
        ),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              ),
      );
    } else {
      avatarChild = Center(
        child: Text(initial,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
      );
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade200,
          child: avatarChild,
        ),
        if (_isUploadingPhoto)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isUploadingPhoto ? Colors.grey : AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}
