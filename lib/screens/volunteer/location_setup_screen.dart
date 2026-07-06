import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../utils/helpers.dart';
import '../charity/location_picker_screen.dart';
import 'volunteer_shell.dart';

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  bool _isLocating = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          Helpers.showSnackBar(context,
              message: 'Location permission is required to find nearby opportunities');
          setState(() => _isLocating = false);
        }
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          Helpers.showSnackBar(context,
              message: 'Please enable location services');
          setState(() => _isLocating = false);
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Reverse geocode for display
      String address = '';
      try {
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [p.locality, p.administrativeArea, p.country]
              .where((s) => s != null && s.isNotEmpty)
              .toList();
          address = parts.join(', ');
        }
      } catch (_) {}

      if (!mounted) return;

      _navigateToHome(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        Helpers.showSnackBar(context,
            message: 'Failed to get location. Please try selecting from map.');
      }
    }
  }

  Future<void> _selectFromMap() async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );

    if (result != null && mounted) {
      _navigateToHome(
        latitude: result.latitude,
        longitude: result.longitude,
        address: result.address,
      );
    }
  }

  void _navigateToHome({
    required double latitude,
    required double longitude,
    required String address,
  }) {
    final provider = context.read<OpportunityProvider>();
    provider.setUserLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
    );

    // Save location to user profile (fire and forget)
    context.read<AuthProvider>().updateProfile(
      latitude: latitude,
      longitude: longitude,
      location: address,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const VolunteerShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0808),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0D0808).withValues(alpha: 0.85),
            ),
          ),

          // Content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(25, 40, 25, bottomPadding + 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(33),
                  topRight: Radius.circular(33),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      IconlyBold.location,
                      size: 32,
                      color: Color(0xFFF4A583),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Set Your Location',
                    style: GoogleFonts.ptSerif(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'We need your location to show volunteer opportunities near you.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF262222).withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Use Current Location button
                  GestureDetector(
                    onTap: _isLocating ? null : _useCurrentLocation,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4A583),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLocating)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else ...[
                            const Icon(IconlyLight.location,
                                size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Use Current Location',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Select from Map button
                  GestureDetector(
                    onTap: _selectFromMap,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: const Color(0xFF262222).withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(IconlyLight.discovery,
                              size: 18,
                              color: const Color(0xFF262222).withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Text(
                            'Select on Map',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF262222).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top logo
          Positioned(
            top: topPadding + 20,
            left: 25,
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo-1.png',
                  width: 24,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Text(
                  'FindYourTwo',
                  style: GoogleFonts.ptSerif(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
