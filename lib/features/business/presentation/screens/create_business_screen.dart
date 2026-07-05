import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ifind/features/business/presentation/screens/location_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;

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
    XFile? logoFile,
    XFile? coverFile,
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
    XFile? logoFile,
    XFile? coverFile,
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
  /// When true the back button is hidden and success navigates to the dashboard,
  /// locking new business owners into completing their shop setup.
  final bool isSetupMode;

  const CreateBusinessScreen({super.key, this.business, this.isSetupMode = false});

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
  XFile? _logoImage;
  XFile? _coverImage;
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
    } else {
      // Pre-fill with the signed-in user's email when creating a new shop
      final user = ref.read(currentUserProvider);
      if (user?.email != null) _emailController.text = user!.email;
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoImage = pickedFile;
        } else {
          _coverImage = pickedFile;
        }
      });
    }
  }

  ImageProvider _xFileImage(XFile f) => kIsWeb
      ? NetworkImage(f.path) as ImageProvider
      : FileImage(File(f.path));

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
          ref.invalidate(myBusinessesStreamProvider(ownerId));
          ref.invalidate(nearbyBusinessesProvider);
          ref.invalidate(featuredBusinessesProvider);
          if (widget.business != null) {
            ref.invalidate(businessStreamProvider(widget.business!.id));
          }

          if (mounted) {
            AppToast.show(
              context,
              widget.business == null ? 'Shop created successfully!' : 'Shop updated successfully!',
              type: ToastType.success,
            );

            // Setup mode: defer navigation one frame so ownerHasShopProvider
            // enters loading state before the redirect logic runs.
            if (widget.isSetupMode) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) context.go('/');
              });
              return;
            }

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
    final existingCover = widget.business?.coverImageUrl;
    final existingLogo = widget.business?.logoUrl;

    ImageProvider? coverProvider;
    if (_coverImage != null) {
      coverProvider = _xFileImage(_coverImage!);
    } else if (existingCover != null) {
      coverProvider = NetworkImage(existingCover);
    }

    ImageProvider? logoProvider;
    if (_logoImage != null) {
      logoProvider = _xFileImage(_logoImage!);
    } else if (existingLogo != null) {
      logoProvider = NetworkImage(existingLogo);
    }

    return Stack(
      children: [
        // Cover photo background
        GestureDetector(
          onTap: () => _pickImage(false),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              image: coverProvider != null
                  ? DecorationImage(image: coverProvider, fit: BoxFit.cover)
                  : null,
            ),
            child: coverProvider == null
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
                image: logoProvider != null
                    ? DecorationImage(image: logoProvider, fit: BoxFit.cover)
                    : null,
              ),
              child: logoProvider == null
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
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
      suffixIcon: suffix,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: const Color(0xFFF0FDF4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  Widget _formSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.deepGreen,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createBusinessProvider);
    final user = ref.watch(currentUserProvider);
    final isLoading = state.isLoading;
    final isEdit = widget.business != null;
    final willAutoUpgrade =
        !isEdit && user?.role == UserRole.customer;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── Hero header — background image + green overlay ──────────
            SliverAppBar(
              expandedHeight: topPad + kToolbarHeight + 190.0,
              pinned: true,
              backgroundColor: AppColors.deepGreen,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: widget.isSetupMode
                  ? null
                  : IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
              title: Text(
                widget.isSetupMode
                    ? 'Set Up Your Shop'
                    : isEdit
                        ? 'Edit Shop Profile'
                        : 'Create Your Shop',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/Color Gradient T-shirts Display.png',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF064E3B).withValues(alpha: 0.92),
                            const Color(0xFF10B981).withValues(alpha: 0.50),
                            const Color(0xFF064E3B).withValues(alpha: 0.96),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: topPad + kToolbarHeight + 8),
                      child: Column(
                        children: [
                          Expanded(child: _buildImageSection()),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(
                              'Tap photos to update',
                              style: GoogleFonts.outfit(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── White sliding form card (auth page pattern) ─────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page heading
                      Text(
                        isEdit ? 'Edit Shop Profile' : 'Create Your Shop',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepGreen,
                          letterSpacing: -0.4,
                        ),
                      ).animate().fadeIn(delay: 180.ms, duration: 500.ms),
                      const SizedBox(height: 4),
                      Text(
                        isEdit
                            ? 'Update your business info and tap Save Changes.'
                            : 'Fill in your shop details to start receiving customers.',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.grey[500]),
                      ).animate().fadeIn(delay: 230.ms, duration: 500.ms),
                      const SizedBox(height: 28),

                      // Setup mode info banner
                      if (widget.isSetupMode) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.primaryGreen
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppColors.primaryGreen, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Complete your shop profile to start receiving customers.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.primaryGreen,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Business Identity ─────────────────────────────
                      _formSection(
                        title: 'Business Identity',
                        icon: Icons.storefront_outlined,
                        color: const Color(0xFF3B82F6),
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
                            textInputAction: TextInputAction.next,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Shop name is required'
                                : null,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<BusinessCategory>(
                            initialValue: _selectedCategory,
                            decoration: _fieldDecoration(
                              label: 'Category',
                              icon: Icons.category_outlined,
                            ),
                            items: BusinessCategory.values.map((cat) {
                              final label = cat.name[0].toUpperCase() +
                                  cat.name.substring(1);
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(label,
                                    style: GoogleFonts.outfit(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: isLoading
                                ? null
                                : (v) {
                                    if (v != null) {
                                      setState(() => _selectedCategory = v);
                                    }
                                  },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            style: GoogleFonts.outfit(),
                            maxLines: 4,
                            decoration: _fieldDecoration(
                              label: 'Description',
                              icon: Icons.description_outlined,
                              hint: 'What do you sell or offer?',
                              alignLabelWithHint: true,
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Description is required'
                                : null,
                            enabled: !isLoading,
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(
                            color: Color(0xFFE8F5E9), thickness: 1.5),
                      ),

                      // ── Location ──────────────────────────────────────
                      _formSection(
                        title: 'Location',
                        icon: Icons.location_on_outlined,
                        color: const Color(0xFFEC4899),
                        children: [
                          TextFormField(
                            controller: _addressController,
                            style: GoogleFonts.outfit(),
                            decoration: _fieldDecoration(
                              label: 'Business Address',
                              icon: Icons.location_on_outlined,
                              hint: 'Street, area, city',
                            ),
                            validator: (v) => !isEdit &&
                                    (v == null || v.trim().length < 6)
                                ? 'A clear business address is required'
                                : null,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isGettingLocation || isLoading
                                      ? null
                                      : _getCurrentLocation,
                                  icon: _isGettingLocation
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.my_location,
                                          size: 16),
                                  label: Text('Use My Location',
                                      style: GoogleFonts.outfit(fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryGreen,
                                    side: const BorderSide(
                                        color: AppColors.primaryGreen),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          final LatLng? result =
                                              await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  LocationPickerScreen(
                                                initialLocation: LatLng(
                                                    _latitude, _longitude),
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
                                  icon: const Icon(Icons.map_outlined,
                                      size: 16),
                                  label: Text('Pick on Map',
                                      style: GoogleFonts.outfit(fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade200, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.pin_drop_outlined,
                                    color: AppColors.primaryGreen, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Lat: ${_latitude.toStringAsFixed(5)},  Lng: ${_longitude.toStringAsFixed(5)}',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(
                            color: Color(0xFFE8F5E9), thickness: 1.5),
                      ),

                      // ── Contact & Web ─────────────────────────────────
                      _formSection(
                        title: 'Contact & Web',
                        icon: Icons.contact_phone_outlined,
                        color: const Color(0xFF10B981),
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            style: GoogleFonts.outfit(),
                            decoration: _fieldDecoration(
                              label: 'Business Phone',
                              icon: Icons.phone_outlined,
                            ),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: (v) => !isEdit &&
                                    (v == null || v.trim().length < 7)
                                ? 'A reachable phone number is required'
                                : null,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            style: GoogleFonts.outfit(),
                            decoration: _fieldDecoration(
                              label: 'Business Email',
                              icon: Icons.alternate_email_rounded,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (!isEdit &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'A business email is required';
                              }
                              if (v != null && v.isNotEmpty) {
                                return Validators.validateEmail(v);
                              }
                              return null;
                            },
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _websiteController,
                            style: GoogleFonts.outfit(),
                            decoration: _fieldDecoration(
                              label: 'Website (Optional)',
                              icon: Icons.language_outlined,
                              hint: 'https://yourshop.com',
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            enabled: !isLoading,
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // ── Submit button — auth page gradient style ───────
                      SizedBox(
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: isLoading
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      AppColors.primaryGreen,
                                      AppColors.deepGreen,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                            color: isLoading ? Colors.grey[300] : null,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: isLoading
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppColors.primaryGreen
                                          .withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<
                                          Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    isEdit
                                        ? 'Save Changes'
                                        : 'Launch My Shop',
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 500.ms)
                          .slideY(begin: 0.1),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              )
                  .animate()
                  .slideY(
                      begin: 0.1,
                      delay: 200.ms,
                      duration: 600.ms,
                      curve: Curves.easeOutCubic)
                  .fadeIn(delay: 200.ms, duration: 500.ms),
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
