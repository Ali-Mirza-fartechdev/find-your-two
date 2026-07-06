import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/charity_provider.dart';
import '../../services/charity_service.dart';
import '../../utils/helpers.dart';

class VolunteerAttendanceScreen extends StatefulWidget {
  final int opportunityId;
  final String eventTitle;

  const VolunteerAttendanceScreen({
    super.key,
    this.opportunityId = 0,
    this.eventTitle = '',
  });

  @override
  State<VolunteerAttendanceScreen> createState() =>
      _VolunteerAttendanceScreenState();
}

class _VolunteerAttendanceScreenState extends State<VolunteerAttendanceScreen> {
  /// Local overrides: participationId → "present" | "absent" | null
  final Map<int, String?> _localAttendance = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _localAttendance.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CharityProvider>().fetchVolunteers(widget.opportunityId);
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  String? _getStatus(AttendanceVolunteer v) {
    if (_localAttendance.containsKey(v.participationId)) {
      return _localAttendance[v.participationId];
    }
    return v.attendanceStatus;
  }

  bool _isPresent(AttendanceVolunteer v) => _getStatus(v) == 'present';
  bool _isAbsent(AttendanceVolunteer v) => _getStatus(v) == 'absent';

  int _getPresentCount(List<AttendanceVolunteer> volunteers) {
    return volunteers.where((v) => _isPresent(v)).length;
  }

  int _getAbsentCount(List<AttendanceVolunteer> volunteers) {
    return volunteers.where((v) => _isAbsent(v)).length;
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: -295,
            top: -261,
            width: 979,
            height: 1499,
            child: SvgPicture.asset(
              'assets/images/home_bg_blob.svg',
              fit: BoxFit.fill,
            ),
          ),
          Consumer<CharityProvider>(
            builder: (context, provider, _) {
              final data = provider.attendanceData;
              final volunteers = data?.volunteers ?? [];
              final totalCount = volunteers.length;
              final presentCount = _getPresentCount(volunteers);
              final absentCount = _getAbsentCount(volunteers);

              return RefreshIndicator(
                color: const Color(0xFFF4A583),
                onRefresh: () => context
                    .read<CharityProvider>()
                    .fetchVolunteers(widget.opportunityId),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildDarkHeader(
                        context,
                        totalCount: totalCount,
                        presentCount: presentCount,
                        absentCount: absentCount,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                        child: Column(
                          children: [
                            _buildListHeader(),
                            const SizedBox(height: 20),
                            // Loading state
                            if (provider.isLoading && data == null)
                              const Padding(
                                padding: EdgeInsets.only(top: 60),
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF4A583),
                                  strokeWidth: 2,
                                ),
                              )
                            // Error state
                            else if (provider.errorMessage != null &&
                                data == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Column(
                                  children: [
                                    const Icon(
                                      IconlyLight.info_circle,
                                      size: 40,
                                      color: Color(0xFFBDBDBD),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      provider.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF262222)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            // Empty state
                            else if (volunteers.isEmpty && !provider.isLoading)
                              Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Column(
                                  children: [
                                    const Icon(
                                      IconlyLight.user_1,
                                      size: 40,
                                      color: Color(0xFFBDBDBD),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No volunteers signed up yet',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF262222)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            // Volunteer list
                            else ...[
                              ...volunteers.map(
                                (v) => Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _buildVolunteerCard(v),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildSaveButton(),
                            ],
                            const SizedBox(height: 150),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Dark Header ──────────────────────────────────────────────────

  Widget _buildDarkHeader(
    BuildContext context, {
    required int totalCount,
    required int presentCount,
    required int absentCount,
  }) {
    return Container(
      width: double.infinity,
      height: 180 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -0.5),
          end: Alignment(1, 1),
          colors: [Color(0xFF262222), Color(0xFF0D0808)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Back + title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (Navigator.of(context).canPop()) ...[
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.23),
                        ),
                      ),
                      child: const Icon(
                        IconlyLight.arrow_left,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volunteer Attendance',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 26.923 / 18,
                        ),
                      ),
                      Text(
                        widget.eventTitle,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 15.385 / 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                _buildStatPill('$totalCount', 'Total', Colors.white),
                const SizedBox(width: 8),
                _buildStatPill(
                  '$presentCount',
                  'Present',
                  const Color(0xFF15B789),
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  '$absentCount',
                  'Absent',
                  const Color(0xFFE41212),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String value, String label, Color valueColor) {
    return Expanded(
      child: Container(
        height: 57.57,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.7),
            width: 0.66,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18.571,
                fontWeight: FontWeight.bold,
                color: valueColor,
                height: 25.999 / 18.571,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
                height: 12.982 / 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── List Header ──────────────────────────────────────────────────

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Volunteer List',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF262222),
          ),
        ),
        GestureDetector(
          onTap: _openQrScanner,
          child: Container(
            height: 26,
            width: 86,
            decoration: BoxDecoration(
              color: const Color(0xFF15B789).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.933),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 10.508,
                  color: Color(0xFF15B789),
                ),
                const SizedBox(width: 4),
                Text(
                  'Scan QR',
                  style: GoogleFonts.inter(
                    fontSize: 9.7,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF15B789),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Volunteer Card ───────────────────────────────────────────────

  Widget _buildVolunteerCard(AttendanceVolunteer volunteer) {
    final present = _isPresent(volunteer);
    final absent = _isAbsent(volunteer);

    return Container(
      height: 68.714,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6.53,
            offset: Offset(0, 2.82),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          if (volunteer.avatarUrl != null && volunteer.avatarUrl!.isNotEmpty)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: volunteer.avatarUrl!,
                width: 40.857,
                height: 40.857,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildDefaultAvatar(),
                errorWidget: (_, __, ___) => _buildDefaultAvatar(),
              ),
            )
          else
            _buildDefaultAvatar(),
          const SizedBox(width: 11),
          // Name + Status
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        volunteer.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF262222),
                          height: 18.571 / 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (volunteer.partySize > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4A583)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'party of ${volunteer.partySize}',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF4A583),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  present
                      ? '\u2713 Present'
                      : absent
                          ? 'Absent'
                          : 'Unmarked',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: present
                        ? const Color(0xFF15B789)
                        : absent
                            ? const Color(0xFFE41212)
                            : const Color(0xFF262222).withValues(alpha: 0.5),
                    height: 14.857 / 10,
                  ),
                ),
              ],
            ),
          ),
          // Present button
          GestureDetector(
            onTap: () {
              setState(() {
                _localAttendance[volunteer.participationId] =
                    present ? null : 'present';
              });
            },
            child: Container(
              width: 33.429,
              height: 33.429,
              decoration: BoxDecoration(
                color: present
                    ? const Color(0xFF15B789)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconlyLight.tick_square,
                size: 14.857,
                color: present
                    ? Colors.white
                    : const Color(0xFF262222).withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(width: 7),
          // Absent button
          GestureDetector(
            onTap: () {
              setState(() {
                _localAttendance[volunteer.participationId] =
                    absent ? null : 'absent';
              });
            },
            child: Container(
              width: 33.429,
              height: 33.429,
              decoration: BoxDecoration(
                color: absent
                    ? const Color(0xFFE41212)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                boxShadow: absent
                    ? const [
                        BoxShadow(
                          color: Color(0x1C000000),
                          blurRadius: 19.411,
                          offset: Offset(0, 2.803),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                IconlyLight.close_square,
                size: 14.857,
                color: absent
                    ? Colors.white
                    : const Color(0xFF262222).withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 40.857,
      height: 40.857,
      decoration: const BoxDecoration(
        color: Color(0x1A10B7A3),
        shape: BoxShape.circle,
      ),
      child: Icon(
        IconlyLight.profile,
        size: 22,
        color: const Color(0xFF10B7A3).withValues(alpha: 0.6),
      ),
    );
  }

  // ─── Save Button ──────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveAttendance,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _isSaving
              ? const Color(0xFF15B789).withValues(alpha: 0.6)
              : const Color(0xFF15B789),
          borderRadius: BorderRadius.circular(99),
        ),
        alignment: Alignment.center,
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Save Attendance',
                style: GoogleFonts.inter(
                  fontSize: 14.857,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ─── QR Scanner ─────────────────────────────────────────────────

  void _openQrScanner() {
    final provider = context.read<CharityProvider>();
    final data = provider.attendanceData;
    if (data == null || data.volunteers.isEmpty) {
      Helpers.showSnackBar(context, message: 'No volunteers to scan');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AttendanceQrScannerPage(
          onScanned: (String scannedValue) {
            // Try to match scanned value to a volunteer (by name or ID)
            for (final v in data.volunteers) {
              if (v.fullName.toLowerCase() == scannedValue.toLowerCase() ||
                  v.volunteerId.toString() == scannedValue ||
                  v.participationId.toString() == scannedValue) {
                setState(() {
                  _localAttendance[v.participationId] = 'present';
                });
                Helpers.showSnackBar(
                  context,
                  message: '${v.fullName} marked present',
                  backgroundColor: const Color(0xFF15B789),
                );
                return;
              }
            }
            Helpers.showSnackBar(
              context,
              message: 'Volunteer not found for scanned code',
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveAttendance() async {
    final provider = context.read<CharityProvider>();
    final volunteers = provider.attendanceData?.volunteers ?? [];

    if (volunteers.isEmpty) return;

    setState(() => _isSaving = true);

    // Build attendance payload from local overrides + server data
    final attendance = volunteers.map((v) {
      final status = _getStatus(v);
      return {
        'participation_id': v.participationId,
        'status': status ?? 'unmarked',
      };
    }).toList();

    final success =
        await provider.saveAttendance(widget.opportunityId, attendance);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      final presentCount = _getPresentCount(volunteers);
      final totalCount = volunteers.length;

      Helpers.showSnackBar(
        context,
        message:
            'Attendance saved! $presentCount of $totalCount marked present',
        backgroundColor: const Color(0xFF15B789),
      );
      Navigator.of(context).pop();
    } else {
      Helpers.showSnackBar(
        context,
        message: provider.errorMessage ?? 'Failed to save attendance',
      );
    }
  }
}

// ─── QR Scanner Page for Attendance ──────────────────────────────────

class _AttendanceQrScannerPage extends StatefulWidget {
  final ValueChanged<String> onScanned;

  const _AttendanceQrScannerPage({required this.onScanned});

  @override
  State<_AttendanceQrScannerPage> createState() =>
      _AttendanceQrScannerPageState();
}

class _AttendanceQrScannerPageState extends State<_AttendanceQrScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(IconlyLight.arrow_left, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scan Volunteer QR',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_hasScanned) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _hasScanned = true;
                final value = barcodes.first.rawValue!;
                Navigator.of(context).pop();
                widget.onScanned(value);
              }
            },
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF4A583), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at volunteer\'s QR code',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
