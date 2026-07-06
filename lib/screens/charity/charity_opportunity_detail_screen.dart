import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/opportunity.dart';
import '../../providers/charity_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../utils/category_utils.dart';
import '../../utils/helpers.dart';
import 'create_opportunity_screen.dart';
import 'volunteer_attendance_screen.dart';

class CharityOpportunityDetailScreen extends StatefulWidget {
  final Opportunity opportunity;

  const CharityOpportunityDetailScreen({
    super.key,
    required this.opportunity,
  });

  @override
  State<CharityOpportunityDetailScreen> createState() =>
      _CharityOpportunityDetailScreenState();
}

class _CharityOpportunityDetailScreenState
    extends State<CharityOpportunityDetailScreen> {
  late Opportunity _opportunity;

  @override
  void initState() {
    super.initState();
    _opportunity = widget.opportunity;
    _refreshOpportunity();
  }

  void _refreshOpportunity() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<OpportunityProvider>();
      await provider.fetchOpportunityById(_opportunity.id);
      final updated = provider.selectedOpportunity;
      if (updated != null && mounted) {
        setState(() => _opportunity = updated);
      }
    });
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
            width: 979,
            height: 1499,
            child: SvgPicture.asset(
              'assets/images/home_bg_blob.svg',
              fit: BoxFit.fill,
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeroImage(context)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCards(),
                      const SizedBox(height: 20),
                      _buildEventStatistics(),
                      const SizedBox(height: 20),
                      _buildMetricsGrid(),
                      const SizedBox(height: 20),
                      _buildEditButton(),
                      const SizedBox(height: 12),
                      _buildQrCodeButton(),
                      const SizedBox(height: 12),
                      _buildManageVolunteersButton(),
                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Hero Image ────────────────────────────────────────────────────

  Widget _buildHeroImage(BuildContext context) {
    final categoryStyle = CategoryUtils.getStyleFromList(_opportunity.category);
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 242 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (_opportunity.imageUrl != null &&
              _opportunity.imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: _opportunity.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: const Color(0xFFF1F5F9),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFF4A583),
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFFF1F5F9),
                child: const Icon(
                  IconlyLight.image,
                  size: 48,
                  color: Color(0xFFBDBDBD),
                ),
              ),
            )
          else
            Container(
              color: const Color(0xFFF1F5F9),
              child: const Icon(
                IconlyLight.image,
                size: 48,
                color: Color(0xFFBDBDBD),
              ),
            ),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00FFFFFF),
                  Color(0x33000000),
                  Color(0xD9000000),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // Back button
          Positioned(
            left: 25,
            top: topPadding + 10,
            child: _buildGlassButton(
              icon: IconlyLight.arrow_left,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          // Share button
          Positioned(
            right: 25,
            top: topPadding + 10,
            child: Builder(
              builder: (ctx) => _buildGlassButton(
                icon: IconlyLight.send,
                onTap: () => _shareOpportunity(ctx),
              ),
            ),
          ),
          // Tag + Title + Org
          Positioned(
            left: 25,
            bottom: 20,
            right: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category tag badge
                Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: categoryStyle.bgColor,
                    borderRadius: BorderRadius.circular(9077),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        categoryStyle.emoji,
                        style: const TextStyle(fontSize: 9, height: 1),
                      ),
                      const SizedBox(width: 2),
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          categoryStyle.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: categoryStyle.textColor,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _opportunity.title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 28.846 / 24,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _opportunity.charityName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 19.231 / 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  // ─── Info Cards (Date, Time, Distance) ─────────────────────────────

  Widget _buildInfoCards() {
    final dateStr = Helpers.formatApiDate(_opportunity.startDatetime);
    final timeStr = Helpers.formatApiTime(_opportunity.startDatetime);
    final distStr = Helpers.formatDistance(_opportunity.distanceKm);

    return Row(
      children: [
        _buildInfoCard(
          IconlyLight.calendar,
          dateStr.isNotEmpty ? dateStr : '--',
          'Date',
        ),
        const SizedBox(width: 8),
        _buildInfoCard(
          IconlyLight.time_circle,
          timeStr.isNotEmpty ? timeStr : '--',
          'Time',
        ),
        const SizedBox(width: 8),
        _buildInfoCard(
          IconlyLight.location,
          distStr.isNotEmpty ? distStr : '--',
          'Distance',
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        height: 89,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14.857, color: const Color(0xFFF4A583)),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.143,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF262222).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Event Statistics ──────────────────────────────────────────────

  Widget _buildEventStatistics() {
    final stats = _opportunity.eventStatistics;
    final signups = _opportunity.volunteerCount;
    final capacity = _opportunity.volunteersNeeded;
    final progress = _opportunity.isUncapped ? 0.0 : _opportunity.progress;
    final capacityPct = (progress * 100).round();

    // Attendance rate from event statistics or fallback
    final rawRate = (stats?['attendance_rate'] as num?)?.toDouble() ?? 0.0;
    // Backend may return as decimal (0.87) or percentage (87) — normalize
    final attendanceRate = rawRate > 1 ? rawRate / 100 : rawRate;
    final attendancePct = (attendanceRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(15),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(IconlyLight.chart,
                  size: 16.7, color: Color(0xFFF4A583)),
              const SizedBox(width: 6),
              Text(
                'Event Statistics',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sign-ups
          _buildStatRow(
            icon: IconlyLight.user_1,
            label: 'Sign-ups',
            value: _opportunity.isUncapped ? '$signups' : '$signups/$capacity',
            progress: progress.clamp(0.0, 1.0),
            subtitle: _opportunity.isUncapped ? 'Uncapped' : '$capacityPct% capacity filled',
          ),
          const SizedBox(height: 16),
          // Attendance Rate
          _buildStatRow(
            icon: IconlyLight.tick_square,
            label: 'Attendance Rate',
            value: '$attendancePct%',
            progress: attendanceRate.clamp(0.0, 1.0),
            subtitle: 'Based on past similar events',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required double progress,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF262222)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF4A583),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(9285),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 11.143,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFFF4A583)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF262222).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // ─── Metrics Grid (2x2) ───────────────────────────────────────────

  Widget _buildMetricsGrid() {
    final stats = _opportunity.eventStatistics;
    final expectedHours =
        (stats?['expected_hours'] as num?)?.toString() ?? '--';
    final impactScore = stats?['impact_score'] != null
        ? '\u2605 ${stats!['impact_score']}'
        : '--';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                  '\u23F1\uFE0F', expectedHours, 'Expected Hours'),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _buildMetricCard(
                  '\uD83C\uDF1F', impactScore, 'Impact Score'),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '\uD83D\uDC65',
                '${_opportunity.volunteerCount}',
                'Volunteers Joined',
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _buildMetricCard(
                '\uD83C\uDFAB',
                '${_opportunity.spotsLeft}',
                'Spots Remaining',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String emoji, String value, String label) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF4A583).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFF4A583).withValues(alpha: 0.6),
          width: 0.805,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
              height: 26 / 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ───────────────────────────────────────────────

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => CreateOpportunityScreen(opportunity: _opportunity),
          ),
        );
        if (result == true && mounted) {
          _refreshOpportunity();
        }
      },
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFF4A583),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IconlyLight.edit, size: 17, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Edit Opportunity',
              style: GoogleFonts.inter(
                fontSize: 13.914,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeButton() {
    return GestureDetector(
      onTap: _generateQrCode,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: const Color(0xFFF4A583),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code, size: 17, color: Color(0xFFF4A583)),
            const SizedBox(width: 8),
            Text(
              'Generate QR Code',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF4A583),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageVolunteersButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VolunteerAttendanceScreen(
              opportunityId: _opportunity.id,
              eventTitle: _opportunity.title,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF262222),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IconlyLight.user_1, size: 17, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Manage Volunteers',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── QR Code Dialog ────────────────────────────────────────────────

  Future<void> _generateQrCode() async {
    final charityProvider = context.read<CharityProvider>();
    await charityProvider.fetchQrToken(_opportunity.id);

    if (!mounted) return;

    final qrData = charityProvider.qrData;
    final error = charityProvider.errorMessage;

    if (error != null) {
      Helpers.showSnackBar(context, message: error);
      return;
    }

    final token = qrData?['qr_token'] as String? ?? qrData?['token'] as String? ?? '';
    final expiresAt = qrData?['expires_at'] as String? ?? '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      size: 36,
                      color: Color(0xFFF4A583),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QR Code Ready',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share this token with volunteers for check-in',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF262222).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          token,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF262222),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (expiresAt.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Expires: ${Helpers.formatApiDate(expiresAt)} ${Helpers.formatApiTime(expiresAt)}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF262222)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4A583),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Share ─────────────────────────────────────────────────────────

  void _shareOpportunity(BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    final dateStr = Helpers.formatApiDate(_opportunity.startDatetime);
    final timeRange = Helpers.formatApiTimeRange(
      _opportunity.startDatetime,
      _opportunity.endDatetime,
    );
    final address = _opportunity.address ?? '';

    Share.share(
      'Check out this opportunity: ${_opportunity.title} by ${_opportunity.charityName}!\n\n$address\n$dateStr\n$timeRange',
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }
}
