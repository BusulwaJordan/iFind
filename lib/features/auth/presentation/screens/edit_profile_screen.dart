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
  String? _imageExt;
  String? _imageUrl;
  bool _isLoading = false;

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
    setState(() {
      _imageBytes = bytes;
      _imageExt = picked.mimeType?.split('/').last.toLowerCase()
          ?? (picked.name.contains('.')
              ? picked.name.split('.').last.toLowerCase()
              : 'jpg');
    });
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

      String? uploadedUrl = _imageUrl;
      if (_imageBytes != null) {
        try {
          final supabase = Supabase.instance.client;
          final ext = _imageExt ?? 'jpg';
          final path = 'avatars/${user.id}.$ext';
          await supabase.storage.from('profile_images').uploadBinary(
            path,
            _imageBytes!,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );
          uploadedUrl = supabase.storage.from('profile_images').getPublicUrl(path);
        } catch (storageErr) {
          if (mounted) {
            AppToast.show(context, 'Photo upload failed: $storageErr', type: ToastType.error);
          }
        }
      }

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
          if (uploadedUrl != null) 'avatar_url': uploadedUrl,
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
        backgroundColor: Colors.white,
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
                onTap: _pickImage,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
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
    final ImageProvider? image = _imageBytes != null
        ? MemoryImage(_imageBytes!) as ImageProvider
        : (_imageUrl != null && _imageUrl!.isNotEmpty)
            ? NetworkImage(_imageUrl!) as ImageProvider
            : null;

    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: image,
          child: image == null
              ? Text(
                  user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}
