import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/validators.dart';
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
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isGettingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated!')),
        );
      }
    } catch (e) {
      setState(() => _isGettingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in')),
        );
        return;
      }

      await ref.read(createBusinessProvider.notifier).saveBusiness(
            ownerId: user.id,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        } else {
          // Success: Invalidate providers to trigger UI updates
          ref.invalidate(myBusinessesProvider(user.id));
          ref.invalidate(nearbyBusinessesProvider);
          ref.invalidate(featuredBusinessesProvider);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.business == null
                    ? 'Shop created successfully!'
                    : 'Shop updated successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          }
        }
      }
    }
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage(false),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              image: _coverImage != null
                  ? DecorationImage(
                      image: FileImage(_coverImage!), fit: BoxFit.cover)
                  : null,
            ),
            child: _coverImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('Add Shop Cover Photo',
                          style: GoogleFonts.outfit(color: Colors.grey)),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _pickImage(true),
          child: Row(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  image: _logoImage != null
                      ? DecorationImage(
                          image: FileImage(_logoImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _logoImage == null
                    ? const Icon(Icons.add_a_photo_outlined, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shop Logo',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  Text('Tap to upload square logo',
                      style:
                          GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createBusinessProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            widget.business == null ? 'Create Your Shop' : 'Edit Shop Details',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildImageSection(),
            const SizedBox(height: 32),
            Text('Shop Details',
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.outfit(),
              decoration: InputDecoration(
                labelText: 'Shop Name',
                hintText: 'e.g. Maria\'s Cakes & Bakes',
                prefixIcon: const Icon(Icons.storefront_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Shop name is required'
                  : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<BusinessCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: BusinessCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              validator: (value) => value == null || value.isEmpty
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Location Picker Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Text('Shop Location',
                          style:
                              GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Accurate location helps customers find you easily.',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isGettingLocation ? null : _getCurrentLocation,
                          icon: _isGettingLocation
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location, size: 16),
                          label: const Text('Auto-Detect'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side:
                                const BorderSide(color: AppColors.primaryGreen),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  return Validators.validateEmail(value);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
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
                          fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
