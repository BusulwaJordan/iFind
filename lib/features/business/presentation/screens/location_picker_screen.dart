import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation ??
        const LatLng(0.3476, 32.5825); // Default to Kampala
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
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
      final newLoc = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLoc;
        _isLocating = false;
      });
      _mapController.move(newLoc, 15);
    } catch (e) {
      setState(() => _isLocating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pin Shop Location',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedLocation),
            child: Text('SAVE',
                style: GoogleFonts.outfit(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation!,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                setState(() => _selectedLocation = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ifind.app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),

          // Instructions Overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10),
                ],
              ),
              child: Text(
                'Tap on the map to pin your exact shop location.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // Current Location Button
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              onPressed: _isLocating ? null : _getCurrentLocation,
              backgroundColor: Colors.white,
              child: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location,
                      color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}
