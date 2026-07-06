import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../models/opportunity.dart';
import '../../providers/opportunity_provider.dart';
import '../../utils/category_utils.dart';
import '../../utils/helpers.dart';
import 'opportunity_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final Completer<GoogleMapController> _mapCompleter = Completer();
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _selectedIndex = 0;

  List<Opportunity> _opportunities = [];
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOpportunities();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadOpportunities() {
    final provider = context.read<OpportunityProvider>();
    final opps = provider.opportunities
        .where((o) =>
            o.latitude != null &&
            o.longitude != null &&
            o.latitude != 0 &&
            o.longitude != 0)
        .toList();

    setState(() {
      _opportunities = opps;
      _markers = _buildMarkers(opps);
    });

    // Fit camera to show all markers
    if (opps.isNotEmpty) {
      _animateToOpportunity(0);
    }
  }

  Set<Marker> _buildMarkers(List<Opportunity> opps) {
    return opps.asMap().entries.map((entry) {
      final index = entry.key;
      final opp = entry.value;
      return Marker(
        markerId: MarkerId('opp_${opp.id}'),
        position: LatLng(opp.latitude!, opp.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          index == _selectedIndex
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueRed,
        ),
        onTap: () => _onMarkerTap(index),
      );
    }).toSet();
  }

  void _onMarkerTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _animateToOpportunity(int index) async {
    if (index >= _opportunities.length) return;
    final opp = _opportunities[index];
    if (opp.latitude == null || opp.longitude == null) return;

    final controller = await _mapCompleter.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(opp.latitude!, opp.longitude!),
        14,
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _markers = _buildMarkers(_opportunities);
    });
    _animateToOpportunity(index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _opportunities.isNotEmpty
                  ? LatLng(
                      _opportunities.first.latitude!,
                      _opportunities.first.longitude!,
                    )
                  : const LatLng(40.7128, -74.0060),
              zoom: 12,
            ),
            onMapCreated: (controller) {
              if (!_mapCompleter.isCompleted) {
                _mapCompleter.complete(controller);
              }
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(IconlyLight.arrow_left,
                        size: 18, color: Color(0xFF262222)),
                  ),
                ),
                const SizedBox(width: 12),
                // Title pill
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconlyBold.location,
                          size: 14, color: Color(0xFFF4A583)),
                      const SizedBox(width: 6),
                      Text(
                        '${_opportunities.length} Opportunities',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF262222),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Empty state
          if (_opportunities.isEmpty)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconlyLight.location,
                        size: 40, color: Color(0xFFBDBDBD)),
                    const SizedBox(height: 8),
                    Text(
                      'No opportunities with locations found',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color:
                            const Color(0xFF262222).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom card carousel
          if (_opportunities.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding + 100,
              height: 140,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _opportunities.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final opp = _opportunities[index];
                  return _buildOpportunityCard(opp);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(Opportunity opp) {
    final catStyle = CategoryUtils.getStyleFromList(opp.category);
    final dateStr = Helpers.formatApiDate(opp.startDatetime);
    final timeStr = Helpers.formatApiTime(opp.startDatetime);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OpportunityDetailScreen(opportunity: opp),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 90,
                height: double.infinity,
                child: opp.imageUrl != null && opp.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: opp.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                          child: const Icon(IconlyLight.image,
                              size: 24, color: Color(0xFFF4A583)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                          child: const Icon(IconlyLight.image,
                              size: 24, color: Color(0xFFF4A583)),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                        child: const Icon(IconlyLight.image,
                            size: 24, color: Color(0xFFF4A583)),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catStyle.bgColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${catStyle.emoji} ${catStyle.displayName}',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: catStyle.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    opp.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Org name
                  Text(
                    opp.charityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color:
                          const Color(0xFF262222).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Date + Time
                  Row(
                    children: [
                      const Icon(IconlyLight.calendar,
                          size: 12, color: Color(0xFFF4A583)),
                      const SizedBox(width: 4),
                      Text(
                        '$dateStr  $timeStr',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF262222)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(IconlyLight.arrow_right_2,
                size: 16, color: Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }
}
