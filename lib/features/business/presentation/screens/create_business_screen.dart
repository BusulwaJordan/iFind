import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/tutorial/app_tutorial.dart';
import 'package:ifind/core/utils/validators.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/domain/usecases/configure_business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/features/business/presentation/screens/location_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';

class CreateBusinessNotifier extends StateNotifier<AsyncValue<void>> {
  final ConfigureBusiness configureBusiness;

  CreateBusinessNotifier({required this.configureBusiness})
      : super(const AsyncValue.data(null));

  Future<void> saveBusiness({
    required String ownerId,
    required String name,
    required String description,
    required BusinessCategory category,
    required double latitude,
    required double longitude,
    String? address,
    String? phone,
    String? website,
    String? email,
    File? logoFile,
    File? coverFile,
    String? businessId, // If null, create new
  }) async {
    state = const AsyncValue.loading();

    final result = businessId == null
        ? await configureBusiness(
            ownerId: ownerId,
            name: name,
            description: description,
            category: category,
            latitude: latitude,
            longitude: longitude,
            address: address,
            phone: phone,
            website: website,
            email: email,
            logoFile: logoFile,
            coverFile: coverFile,
          )
        : await _updateBusiness(
            businessId: businessId,
            name: name,
            description: description,
            phone: phone,
            address: address,
            logoFile: logoFile,
            coverFile: coverFile,
          );

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<Either<Failure, Business>> _updateBusiness({
    required String businessId,
    String? name,
    String? description,
    String? phone,
    String? address,
    File? logoFile,
    File? coverFile,
  }) async {
    return await configureBusiness.repository.updateBusiness(
      businessId: businessId,
      name: name,
      description: description,
      phone: phone,
      address: address,
      logoFile: logoFile,
      coverFile: coverFile,
    );
  }
}

final createBusinessProvider =
    StateNotifierProvider<CreateBusinessNotifier, AsyncValue<void>>((ref) {
  return CreateBusinessNotifier(
    configureBusiness: ConfigureBusiness(ref.watch(businessRepositoryProvider)),
  );
});

class CreateBusinessScreen extends ConsumerStatefulWidget {
  final Business? business;

  const CreateBusinessScreen({super.key, this.business});

  @override
  ConsumerState<CreateBusinessScreen> createState() =>
      _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends ConsumerState<CreateBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  BusinessCategory _selectedCategory = BusinessCategory.retail;

  double _latitude = 0.3476;
  double _longitude = 32.5825;
  bool _isGettingLocation = false;
  File? _logoImage;
  File? _coverImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.business != null) {
      _nameController.text = widget.business!.name;
      _descriptionController.text = widget.business!.description;
      _addressController.text = widget.business!.address ?? '';
      _phoneController.text = widget.business!.phone ?? '';
      _emailController.text = widget.business!.email ?? '';
      _websiteController.text = widget.business!.website ?? '';
      _selectedCategory = widget.business!.category;
      _latitude = widget.business!.latitude;
      _longitude = widget.business!.longitude;
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoImage = File(pickedFile.path);
        } else {
          _coverImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception('Please turn on location services and try again.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        throw Exception(
          'Location permission is blocked. Enable it in app settings.',
        );
      }

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw Exception('Location permission is required.');
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isGettingLocation = false;
      });
      if (mounted) {
        AppToast.show(context, 'Location updated!', type: ToastType.success);
      }
    } catch (e) {
      setState(() => _isGettingLocation = false);
      if (mounted) {
        AppToast.show(context, friendlyError(e), type: ToastType.error);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        AppToast.show(context, 'You must be logged in', type: ToastType.error);
        return;
      }

      var ownerId = user.id;
      if (widget.business == null && user.role == UserRole.customer) {
        final upgradeError =
            await ref.read(authProvider.notifier).upgradeToBusinessOwner();
        if (upgradeError != null) {
          if (!mounted) return;
          AppToast.show(context, upgradeError, type: ToastType.error);
          return;
        }
        ownerId = ref.read(currentUserProvider)?.id ?? user.id;
      }

      await ref.read(createBusinessProvider.notifier).saveBusiness(
            ownerId: ownerId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            latitude: _latitude,
            longitude: _longitude,
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            website: _websiteController.text.trim().isEmpty
                ? null
                : _websiteController.text.trim(),
            logoFile: _logoImage,
            coverFile: _coverImage,
            businessId: widget.business?.id,
          );

      if (mounted) {
        final state = ref.read(createBusinessProvider);
        if (state.hasError) {
          AppToast.show(context, friendlyError(state.error!), type: ToastType.error);
        } else {
          // Success: Invalidate providers to trigger UI updates
          ref.invalidate(myBusinessesProvider(ownerId));
          ref.invalidate(nearbyBusinessesProvider);
          ref.invalidate(featuredBusinessesProvider);

          if (mounted) {
            AppToast.show(
              context,
              widget.business == null ? 'Shop created successfully!' : 'Shop updated successfully!',
              type: ToastType.success,
            );
            if (widget.business == null &&
                ref
                    .read(tutorialProvider)
                    .shouldShow(AppTutorialService.businessSetupKey)) {
              await showAppTutorial(
                context: context,
                ref: ref,
                storageKey: AppTutorialService.businessSetupKey,
                steps: const [
                  TutorialStep(
                    icon: Icons.dashboard_customize_rounded,
                    title: 'Your business command center',
                    description:
                        'My Shop shows your profile health, reviews, nearby demand, conversations, and the main tools for managing the business customers see.',
                    action: 'Open My Shop anytime from the bottom navigation.',
                  ),
                  TutorialStep(
                    icon: Icons.inventory_2_rounded,
                    title: 'Use inventory for products',
                    description:
                        'Inventory is your public catalog. Add products with prices, photos, stock quantity, and availability so customers know exactly what you sell.',
                    action:
                        'Tap Inventory or Manage Catalog, then Add Product.',
                  ),
                  TutorialStep(
                    icon: Icons.photo_library_rounded,
                    title: 'Build trust with media',
                    description:
                        'Gallery and business images help customers recognize your shop, inspect your work, and feel confident before contacting you.',
                    action:
                        'Add clear product, service, shop-front, or portfolio photos.',
                  ),
                  TutorialStep(
                    icon: Icons.trending_up_rounded,
                    title: 'Follow leads and performance',
                    description:
                        'Leads show nearby customer needs that match your category. Analytics help you see views, saved shops, inquiries, product coverage, and review health.',
                    action:
                        'Check leads often and respond quickly to active demand.',
                  ),
                  TutorialStep(
                    icon: Icons.handshake_rounded,
                    title: 'Connect with other businesses',
                    description:
                        'Partner recommendations help you find compatible businesses near you for supply, referrals, collaborations, and B2B conversations.',
                    action:
                        'Review suggested partners and start a conversation when useful.',
                  ),
                ],
              );
            }
            if (!mounted) return;
            Navigator.pop(context);
          }
        }
      }
    }
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Cover photo background
        GestureDetector(
          onTap: () => _pickImage(false),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              image: _coverImage != null
                  ? DecorationImage(
                      image: FileImage(_coverImage!), fit: BoxFit.cover)
                  : null,
            ),
            child: _coverImage == null
                ? Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            size: 36, color: Colors.white70),
                        const SizedBox(height: 8),
                        Text(
                          'Add Cover Photo',
                          style: GoogleFonts.outfit(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: Center(
                      child: Text(
                        'Tap to change cover',
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ),
          ),
        ),
        // Logo overlay
        Positioned(
          bottom: 0,
          left: 24,
          child: GestureDetector(
            onTap: () => _pickImage(true),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: Colors.white.withValues(alpha: 0.15),
                image: _logoImage != null
                    ? DecorationImage(
                        image: FileImage(_logoImage!), fit: BoxFit.cover)
                    : null,
              ),
              child: _logoImage == null
                  ? const Icon(Icons.add_a_photo_outlined,
                      color: Colors.white, size: 28)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createBusinessProvider);
    final user = ref.watch(currentUserProvider);
    final isLoading = state.isLoading;
    final willAutoUpgrade =
        widget.business == null && user?.role == UserRole.customer;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppColors.deepGreen,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              title: Text(
                widget.business == null ? 'Create Your Shop' : 'Edit Shop',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.deepGreen, AppColors.primaryGreen],
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 56),
                      Expanded(
                        child: _buildImageSection(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Tap to change photos',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Business Identity
                    _sectionCard(
                      title: 'Business Identity',
                      children: [
                        if (willAutoUpgrade) ...[
                          _buildAutoUpgradeNotice(),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.outfit(),
                          decoration: _fieldDecoration(
                            label: 'Shop Name',
                            icon: Icons.storefront_outlined,
                            hint: "e.g. Maria's Cakes & Bakes",
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Shop name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<BusinessCategory>(
                          initialValue: _selectedCategory,
                          decoration: _fieldDecoration(
                            label: 'Category',
                            icon: Icons.category_outlined,
                          ),
                          items: BusinessCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category.name.toUpperCase(),
                                style: GoogleFonts.outfit(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          style: GoogleFonts.outfit(),
                          decoration: _fieldDecoration(
                            label: 'Description',
                            icon: Icons.description_outlined,
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Description is required'
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Section 2: Location
                    _sectionCard(
                      title: 'Location',
                      children: [
                        TextFormField(
                          controller: _addressController,
                          style: GoogleFonts.outfit(),
                          decoration: _fieldDecoration(
                            label: 'Business Address',
                            icon: Icons.location_on_outlined,
                          ),
                          validator: (value) => widget.business == null &&
                                  (value == null || value.trim().length < 6)
                              ? 'A clear business address is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isGettingLocation
                                    ? null
                                    : _getCurrentLocation,
                                icon: _isGettingLocation
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.my_location, size: 16),
                                label: const Text('Use My Location'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryGreen,
                                  side: const BorderSide(
                                      color: AppColors.primaryGreen),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final LatLng? result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LocationPickerScreen(
                                        initialLocation:
                                            LatLng(_latitude, _longitude),
                                      ),
                                    ),
                                  );
                                  if (result != null) {
                                    setState(() {
                                      _latitude = result.latitude;
                                      _longitude = result.longitude;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.map_outlined, size: 16),
                                label: const Text('Pick on Map'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Lat: ${_latitude.toStringAsFixed(6)}, Long: ${_longitude.toStringAsFixed(6)}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Section 3: Contact & Web
                    _sectionCard(
                      title: 'Contact & Web',
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          style: GoogleFonts.outfit(),
                          decoration: _fieldDecoration(
                            label: 'Business Phone',
                            icon: Icons.phone_outlined,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) => widget.business == null &&
                                  (value == null || value.trim().length < 7)
                              ? 'A reachable business phone is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          style: GoogleFonts.outfit(),
                          decoration: _fieldDecoration(
                            label: 'Business Email',
                            icon: Icons.email_outlined,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (widget.business == null &&
                                (value == null || value.trim().isEmpty)) {
                              return 'A business email is required';
                            }
                            if (value != null && value.isNotEmpty) {
                              return Validators.validateEmail(value);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _websiteController,
                          style: GoogleFonts.outfit(),
                          decoration: _fieldDecoration(
                            label: 'Website (Optional)',
                            icon: Icons.language_outlined,
                          ),
                          keyboardType: TextInputType.url,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                widget.business == null
                                    ? 'Launch My Shop'
                                    : 'Save Changes',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoUpgradeNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppColors.primaryGreen,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Submitting a valid shop will automatically upgrade your customer account to a business account and approve the shop using iFind trust checks.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.darkText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
