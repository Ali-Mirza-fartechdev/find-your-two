import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconly/iconly.dart';
import '../../utils/helpers.dart';

class LocationPickerResult {
  final String address;
  final double latitude;
  final double longitude;

  LocationPickerResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;
  /// Extra bottom offset to clear a parent nav bar (e.g. charity shell).
  final double bottomOffset;

  const LocationPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
    this.bottomOffset = 16,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _searchCtrl = TextEditingController();
  final Completer<GoogleMapController> _mapCompleter = Completer();

  LatLng _pickedLatLng = const LatLng(40.7128, -74.0060);
  String? _resolvedAddress;
  bool _isSearching = false;
  bool _isLocating = false;
  bool _hasSelection = false;

  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _pickedLatLng = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _resolvedAddress = widget.initialAddress;
      _hasSelection = true;
    }
    if (widget.initialAddress != null) {
      _searchCtrl.text = widget.initialAddress!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ─── Search ────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(query.trim());
    });
  }

  Future<void> _searchAddress(String query) async {
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(query);
      final results = <Map<String, dynamic>>[];

      for (final loc in locations.take(5)) {
        final placemarks =
            await placemarkFromCoordinates(loc.latitude, loc.longitude);
        String displayName = query;
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [p.street, p.locality, p.administrativeArea, p.country]
              .where((s) => s != null && s.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) displayName = parts.join(', ');
        }
        results.add({
          'display_name': displayName,
          'lat': loc.latitude,
          'lng': loc.longitude,
        });
      }

      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    }
    if (mounted) setState(() => _isSearching = false);
  }

  Future<void> _selectSearchResult(Map<String, dynamic> place) async {
    final lat = place['lat'] as double;
    final lng = place['lng'] as double;
    final address = place['display_name'] as String;

    setState(() {
      _pickedLatLng = LatLng(lat, lng);
      _resolvedAddress = address;
      _searchCtrl.text = address;
      _searchResults = [];
      _hasSelection = true;
    });

    final controller = await _mapCompleter.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(_pickedLatLng, 15));
  }

  // ─── Map tap ───────────────────────────────────────────────────────

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _pickedLatLng = position;
      _hasSelection = true;
      _searchResults = [];
    });

    try {
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = [p.street, p.locality, p.administrativeArea, p.country]
            .where((s) => s != null && s.isNotEmpty)
            .toList();
        final address = parts.isNotEmpty
            ? parts.join(', ')
            : '${position.latitude}, ${position.longitude}';
        setState(() {
          _resolvedAddress = address;
          _searchCtrl.text = address;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedAddress =
              '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        });
      }
    }
  }

  // ─── Current location ──────────────────────────────────────────────

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          Helpers.showSnackBar(context, message: 'Location permission denied');
        }
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final latLng = LatLng(position.latitude, position.longitude);

      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      String address =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.street, p.locality, p.administrativeArea, p.country]
            .where((s) => s != null && s.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) address = parts.join(', ');
      }

      final controller = await _mapCompleter.future;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

      if (!mounted) return;
      setState(() {
        _pickedLatLng = latLng;
        _resolvedAddress = address;
        _searchCtrl.text = address;
        _hasSelection = true;
      });
    } catch (_) {
      if (mounted) {
        Helpers.showSnackBar(
            context, message: 'Failed to get current location');
      }
    }
    if (mounted) setState(() => _isLocating = false);
  }

  // ─── Confirm ───────────────────────────────────────────────────────

  void _confirmLocation() {
    if (!_hasSelection) {
      Helpers.showSnackBar(context,
          message: 'Tap the map or search an address first');
      return;
    }
    Navigator.of(context).pop(LocationPickerResult(
      address: _resolvedAddress ?? _searchCtrl.text.trim(),
      latitude: _pickedLatLng.latitude,
      longitude: _pickedLatLng.longitude,
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF262222).withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF262222).withValues(alpha: 0.6),
                  width: 0.685,
                ),
              ),
              child: const Icon(IconlyLight.arrow_left,
                  size: 16, color: Color(0xFF262222)),
            ),
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'Select Location',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF262222),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLatLng,
              zoom: 13,
            ),
            onMapCreated: (controller) {
              if (!_mapCompleter.isCompleted) {
                _mapCompleter.complete(controller);
              }
            },
            onTap: _onMapTap,
            markers: _hasSelection
                ? {
                    Marker(
                      markerId: const MarkerId('picked'),
                      position: _pickedLatLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange),
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Search bar + results
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFF4A583).withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          cursorColor: const Color(0xFFF4A583),
                          style: GoogleFonts.inter(
                              fontSize: 13, color: const Color(0xFF262222)),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Search location...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF262222).withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 14),
                            prefixIcon: Icon(IconlyLight.search,
                                size: 18,
                                color: const Color(0xFF262222).withValues(alpha: 0.5)),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFFF4A583)),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color:
                            const Color(0xFF262222).withValues(alpha: 0.05),
                      ),
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(IconlyLight.location,
                              size: 16, color: Color(0xFFF4A583)),
                          title: Text(
                            place['display_name'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF262222),
                            ),
                          ),
                          onTap: () => _selectSearchResult(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Current location button
          Positioned(
            right: 16,
            bottom: _hasSelection
                ? 120 + widget.bottomOffset
                : 16 + widget.bottomOffset,
            child: GestureDetector(
              onTap: _isLocating ? null : _useCurrentLocation,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFFF4A583)),
                          )
                        : const Icon(IconlyLight.location,
                            size: 20, color: Color(0xFFF4A583)),
                    const SizedBox(width: 6),
                    Text(
                      'My Location',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF4A583),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Floating location detail card
          if (_hasSelection && _resolvedAddress != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + widget.bottomOffset,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Location icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(IconlyBold.location,
                          size: 16, color: Color(0xFFF4A583)),
                    ),
                    const SizedBox(width: 12),
                    // Address + coords
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _resolvedAddress!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF262222),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_pickedLatLng.latitude.toStringAsFixed(5)}, ${_pickedLatLng.longitude.toStringAsFixed(5)}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF262222)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Confirm checkmark button
                    GestureDetector(
                      onTap: _confirmLocation,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF15B789),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(IconlyBold.tick_square,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
