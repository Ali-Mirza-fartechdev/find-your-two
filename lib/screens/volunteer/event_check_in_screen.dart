import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/opportunity.dart';
import '../../providers/checkin_provider.dart';
import '../../utils/helpers.dart';

class EventCheckInScreen extends StatefulWidget {
  final Opportunity opportunity;

  const EventCheckInScreen({
    super.key,
    required this.opportunity,
  });

  @override
  State<EventCheckInScreen> createState() => _EventCheckInScreenState();
}

class _EventCheckInScreenState extends State<EventCheckInScreen> {
  bool _isGpsLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckinProvider>().clearState();
    });
  }

  void _openQRScanner() {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _QRScannerPage(
            onScanned: (code) {
              Navigator.of(context).pop();
              _handleQrCheckin(code);
            },
          ),
        ),
      );
    } catch (_) {
      Helpers.showSnackBar(
        context,
        message: 'QR Scanner not available. Try GPS Check-In instead.',
      );
    }
  }

  Future<void> _handleQrCheckin(String qrToken) async {
    final provider = context.read<CheckinProvider>();
    final success = await provider.checkinViaQr(
      widget.opportunity.id,
      qrToken,
    );

    if (!mounted) return;

    if (success) {
      final result = provider.result;
      Helpers.showSnackBar(
        context,
        message:
            'Checked in successfully! ${result?.hoursAwarded ?? 0} hours awarded.',
        backgroundColor: const Color(0xFF15B789),
      );
      Navigator.of(context).pop(true);
    } else {
      Helpers.showSnackBar(
        context,
        message: provider.errorMessage ?? 'Check-in failed',
      );
      provider.clearError();
    }
  }

  Future<void> _handleGPSCheckIn() async {
    if (_isGpsLoading) return;

    setState(() => _isGpsLoading = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            message: 'Location services are disabled. Please enable them.',
          );
        }
        setState(() => _isGpsLoading = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            Helpers.showSnackBar(
              context,
              message: 'Location permission denied',
            );
          }
          setState(() => _isGpsLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            message:
                'Location permission permanently denied. Enable in Settings.',
          );
        }
        setState(() => _isGpsLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      final provider = context.read<CheckinProvider>();
      final success = await provider.checkinViaGps(
        widget.opportunity.id,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      setState(() => _isGpsLoading = false);

      if (success) {
        final result = provider.result;
        Helpers.showSnackBar(
          context,
          message:
              'Checked in via GPS! ${result?.hoursAwarded ?? 0} hours awarded.',
          backgroundColor: const Color(0xFF15B789),
        );
        Navigator.of(context).pop(true);
      } else {
        Helpers.showSnackBar(
          context,
          message: provider.errorMessage ?? 'GPS check-in failed',
        );
        provider.clearError();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGpsLoading = false);
        final msg = e.toString().contains('TimeoutException')
            ? 'Location request timed out. Please try again.'
            : 'Failed to get location. Make sure location services are enabled.';
        Helpers.showSnackBar(context, message: msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: -295,
            top: -261,
            width: 894,
            height: 1308,
            child: SvgPicture.asset(
              'assets/images/home_bg_blob.svg',
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildEventInfoCard(),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Divider(
                      color:
                          const Color(0xFF262222).withValues(alpha: 0.1),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildVerifySection(),
                  const SizedBox(height: 20),
                  _buildQRCodeCard(),
                  const SizedBox(height: 15),
                  _buildGPSCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
              child: const Icon(
                IconlyLight.arrow_left,
                size: 16,
                color: Color(0xFF262222),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Event Check-In',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                  height: 26.923 / 18,
                ),
              ),
              Text(
                'Verify your Attendance',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF262222),
                  height: 15.385 / 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfoCard() {
    final opp = widget.opportunity;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: const Color(0xFFF4A583).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFF4A583)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: opp.imageUrl != null && opp.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: opp.imageUrl!,
                          fit: BoxFit.cover,
                          width: 78,
                          height: 64,
                          errorWidget: (_, _, _) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      opp.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF262222),
                        height: 15 / 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      opp.charityName,
                      style: GoogleFonts.inter(
                        fontSize: 11.143,
                        color: const Color(0xFF262222)
                            .withValues(alpha: 0.5),
                        height: 14.857 / 11.143,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${Helpers.formatApiDate(opp.startDatetime)} · ${Helpers.formatApiTimeRange(opp.startDatetime, opp.endDatetime)}',
                      style: GoogleFonts.inter(
                        fontSize: 11.143,
                        color: const Color(0xFF262222)
                            .withValues(alpha: 0.5),
                        height: 14.857 / 11.143,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(IconlyLight.heart, size: 24, color: Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _buildVerifySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify Attendance',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
              height: 22.286 / 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Choose your preferred verification method to check in at the event.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
              height: 20.946 / 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: GestureDetector(
        onTap: _openQRScanner,
        child: Container(
          height: 124.429,
          padding: const EdgeInsets.symmetric(horizontal: 19.5),
          decoration: BoxDecoration(
            color: const Color(0xFF15B789).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.01),
            border: Border.all(
              color: const Color(0xFF15B789),
              width: 0.929,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1C000000),
                blurRadius: 17.643,
                offset: Offset(0, 1.857),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48.286,
                height: 48.286,
                decoration: BoxDecoration(
                  color: const Color(0xFF15B789).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22.286),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  size: 26,
                  color: Color(0xFF15B789),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'QR Code Scanner',
                      style: GoogleFonts.inter(
                        fontSize: 12.071,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF262222),
                        height: 17.245 / 12.071,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan the event QR code shown by the organizer',
                      style: GoogleFonts.inter(
                        fontSize: 11.143,
                        color: const Color(0xFF262222)
                            .withValues(alpha: 0.5),
                        height: 19.45 / 11.143,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Recommended →',
                      style: GoogleFonts.inter(
                        fontSize: 11.143,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF15B789),
                        height: 14.857 / 11.143,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGPSCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: GestureDetector(
        onTap: _isGpsLoading ? null : _handleGPSCheckIn,
        child: Container(
          height: 122.571,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13.929),
            border: Border.all(
              color: const Color(0xFFF4A583).withValues(alpha: 0.0),
              width: 0.929,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1C000000),
                blurRadius: 18.135,
                offset: Offset(0, 2.619),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48.286,
                height: 48.286,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(91.929),
                ),
                child: _isGpsLoading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF4A583),
                          ),
                        ),
                      )
                    : const Icon(
                        IconlyLight.location,
                        size: 26,
                        color: Color(0xFFF4A583),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'GPS Check-In',
                      style: GoogleFonts.inter(
                        fontSize: 12.071,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF262222),
                        height: 17.245 / 12.071,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isGpsLoading
                          ? 'Getting your location...'
                          : 'Automatically verify using your location at the event',
                      style: GoogleFonts.inter(
                        fontSize: 11.143,
                        color: const Color(0xFF262222)
                            .withValues(alpha: 0.5),
                        height: 19.45 / 11.143,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Requires GPS access',
                      style: GoogleFonts.inter(
                        fontSize: 11.143,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF262222),
                        height: 14.857 / 11.143,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── QR Scanner Full Screen Page ─────────────────────────────────────

class _QRScannerPage extends StatefulWidget {
  final ValueChanged<String> onScanned;

  const _QRScannerPage({required this.onScanned});

  @override
  State<_QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<_QRScannerPage> {
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_hasScanned) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _hasScanned = true;
                widget.onScanned(barcodes.first.rawValue!);
              }
            },
            errorBuilder: (_, _) => Center(
              child: Text(
                'Camera not available',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            IconlyLight.close_square,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Scan QR Code',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF4A583),
                      width: 2,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Point your camera at the event QR code',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
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
