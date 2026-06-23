import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class StartupLocationPrompt extends StatefulWidget {
  const StartupLocationPrompt({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<StartupLocationPrompt> createState() => _StartupLocationPromptState();
}

class _StartupLocationPromptState extends State<StartupLocationPrompt> {
  bool _hasCheckedLocation = false;
  bool _isShowingPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptForLocationIfNeeded();
    });
  }

  Future<void> _promptForLocationIfNeeded() async {
    if (_hasCheckedLocation || _isShowingPrompt || !mounted) return;
    _hasCheckedLocation = true;

    var permission = await Geolocator.checkPermission();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;

    if (serviceEnabled &&
        (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always)) {
      return;
    }

    _isShowingPrompt = true;
    final shouldEnable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.my_location_rounded),
        title: const Text('Turn on location'),
        content: const Text(
          'iFind needs your location for the most accurate nearby shops, recommendations, and search results.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.location_on_rounded),
            label: const Text('Turn on'),
          ),
        ],
      ),
    );
    _isShowingPrompt = false;

    if (!mounted || shouldEnable != true) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    if ((permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) &&
        !serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
