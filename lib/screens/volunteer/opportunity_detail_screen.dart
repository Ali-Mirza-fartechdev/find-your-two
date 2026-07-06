import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/opportunity.dart';
import '../../providers/opportunity_provider.dart';
import '../../utils/category_utils.dart';
import '../../utils/helpers.dart';
import 'enrollment_screen.dart';

class OpportunityDetailScreen extends StatefulWidget {
  final Opportunity opportunity;

  const OpportunityDetailScreen({
    super.key,
    required this.opportunity,
  });

  @override
  State<OpportunityDetailScreen> createState() =>
      _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  bool _isRefreshing = true;
  late Opportunity _opportunity;
  bool _isSaved = false;

  Opportunity get opportunity => _opportunity;

  @override
  void initState() {
    super.initState();
    _opportunity = widget.opportunity;
    _isSaved = widget.opportunity.isSaved;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOpportunity();
    });
  }

  Future<void> _refreshOpportunity() async {
    if (mounted) setState(() => _isRefreshing = true);
    final provider = context.read<OpportunityProvider>();
    await provider.fetchOpportunityById(_opportunity.id);
    if (mounted) {
      setState(() {
        if (provider.selectedOpportunity != null) {
          _opportunity = provider.selectedOpportunity!;
          _isSaved = _opportunity.isSaved;
        }
        _isRefreshing = false;
      });
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
            top: 0,
            width: 903,
            height: 1938,
            child: SvgPicture.asset(
              'assets/images/home_bg_blob.svg',
              fit: BoxFit.fill,
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeroImage(context)),
              SliverToBoxAdapter(
                child: _isRefreshing
                    ? const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF4A583),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoGrid(),
                            ..._buildBadgesSection(),
                            const SizedBox(height: 30),
                            _buildVolunteersJoined(),
                            const SizedBox(height: 30),
                            _buildAboutSection(),
                            const SizedBox(height: 30),
                            _buildExpectedImpact(),
                            const SizedBox(height: 15),
                            _buildEnrollButton(),
                            const SizedBox(height: 30),
                            _buildOrganizer(),
                            const SizedBox(height: 30),
                            _buildLocationSection(context),
                            const SizedBox(height: 20),
                            _buildActivityTags(),
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

  Widget _buildHeroImage(BuildContext context) {
    final style = CategoryUtils.getStyleFromList(opportunity.category);

    return SizedBox(
      height: 242 + MediaQuery.of(context).padding.top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(),
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
          Positioned(
            left: 25,
            top: MediaQuery.of(context).padding.top + 10,
            child: _buildGlassButton(
              icon: IconlyLight.arrow_left,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            right: 65,
            top: MediaQuery.of(context).padding.top + 10,
            child: _buildGlassButton(
              icon: _isSaved ? Icons.favorite : Icons.favorite_border,
              iconColor: _isSaved ? const Color(0xFFF4A583) : Colors.white,
              onTap: () => _toggleSave(),
            ),
          ),
          Positioned(
            right: 25,
            top: MediaQuery.of(context).padding.top + 10,
            child: Builder(
              builder: (ctx) => _buildGlassButton(
                icon: IconlyLight.send,
                onTap: () => _shareOpportunity(ctx),
              ),
            ),
          ),
          Positioned(
            left: 25,
            bottom: 20,
            right: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: style.bgColor,
                    borderRadius: BorderRadius.circular(9077),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(style.emoji,
                          style: const TextStyle(fontSize: 9, height: 1)),
                      const SizedBox(width: 2),
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          style.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: style.textColor,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Posted By ${opportunity.charityName.isNotEmpty ? opportunity.charityName : "Organization"}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 19.231 / 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  opportunity.title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 28.846 / 24,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  opportunity.charityName,
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

  Widget _buildImage() {
    if (opportunity.imageUrl != null && opportunity.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: opportunity.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
        errorWidget: (_, _, _) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(IconlyLight.image, size: 48, color: Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
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
        child: Icon(icon, size: 16, color: iconColor ?? Colors.white),
      ),
    );
  }

  Widget _buildInfoGrid() {
    final dateStr = Helpers.formatApiDate(opportunity.startDatetime);
    final timeStr = Helpers.formatApiTimeRange(
        opportunity.startDatetime, opportunity.endDatetime);
    final distanceStr = Helpers.formatDistance(opportunity.distanceKm);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: IconlyLight.calendar,
                label: 'Date',
                value: dateStr.isNotEmpty ? dateStr : '-',
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _buildInfoCard(
                icon: IconlyLight.time_circle,
                label: 'Time',
                value: timeStr.isNotEmpty ? timeStr : '-',
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: IconlyLight.location,
                label: opportunity.address ?? 'Location',
                value: distanceStr.isNotEmpty ? distanceStr : '-',
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _buildInfoCard(
                icon: IconlyLight.user_1,
                label: 'Spots available',
                value: opportunity.isUncapped
                    ? 'Open'
                    : '${opportunity.spotsLeft} left',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      height: 98,
      padding: const EdgeInsets.all(13),
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
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF4A583).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: const Color(0xFFF4A583)),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.143,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
              height: 14.857 / 11.143,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
              height: 16.25 / 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteersJoined() {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Volunteers Joined',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                ),
              ),
              Text(
                opportunity.isUncapped
                    ? '${opportunity.volunteerCount}'
                    : '${opportunity.volunteerCount}/${opportunity.volunteersNeeded}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF4A583),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!opportunity.isUncapped) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(9285),
              child: LinearProgressIndicator(
                value: opportunity.progress,
                minHeight: 7.429,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFF4A583),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              opportunity.isUncapped
                  ? 'No limit — all are welcome!'
                  : "${opportunity.spotsLeft} spots remaining — don't miss your chance!",
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF262222).withValues(alpha: 0.5),
                height: 14.857 / 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About This Event',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF262222),
            height: 22.286 / 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          opportunity.description ?? 'No description available.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF262222).withValues(alpha: 0.5),
            height: 20.946 / 12,
          ),
        ),
      ],
    );
  }

  Widget _buildExpectedImpact() {
    return Container(
      padding: const EdgeInsets.all(15),
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
        children: [
          Row(
            children: [
              const Text('🌍', style: TextStyle(fontSize: 16.714)),
              const SizedBox(width: 8),
              Text(
                'Expected Impact',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Make a difference by volunteering your time',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollButton() {
    if (opportunity.isEnrolled) {
      return SizedBox(
        width: double.infinity,
        height: 37,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF15B789),
            disabledBackgroundColor: const Color(0xFF15B789),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.156),
            ),
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            opportunity.isCheckedIn ? '✓ Checked In' : '✓ Enrolled',
            style: GoogleFonts.inter(
              fontSize: 12.709,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (opportunity.isExternal) {
      return SizedBox(
        width: double.infinity,
        height: 37,
        child: OutlinedButton.icon(
          onPressed: () => _openExternalSignup(),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF4A583),
            side: const BorderSide(color: Color(0xFFF4A583), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.156),
            ),
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          icon: const Icon(Icons.open_in_new, size: 14),
          label: Text(
            'Sign Up Externally',
            style: GoogleFonts.inter(
              fontSize: 12.709,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF4A583),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 37,
      child: ElevatedButton(
        onPressed: opportunity.isFull
            ? null
            : () async {
                final enrolled = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        EnrollmentScreen(opportunity: opportunity),
                  ),
                );
                if (enrolled == true && mounted) {
                  _refreshOpportunity();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF4A583),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.156),
          ),
          side: const BorderSide(color: Color(0xFFF4A583), width: 1),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          opportunity.isFull ? 'Opportunity Full' : 'Enroll Now',
          style: GoogleFonts.inter(
            fontSize: 12.709,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOrganizer() {
    final charity = opportunity.charity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organizer',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF262222),
            height: 22.286 / 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
          child: Row(
            children: [
              Container(
                width: 44.571,
                height: 44.571,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF4A583).withValues(alpha: 0.6),
                    width: 0.805,
                  ),
                ),
                child: charity?.logoUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: charity!.logoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const Center(
                            child: Text('🌿', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      )
                    : const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 22)),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.charityName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF262222),
                        height: 22.286 / 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      charity?.verified == true
                          ? 'Verified Charity Organization'
                          : 'Charity Organization',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF262222).withValues(alpha: 0.5),
                        height: 14.857 / 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (charity?.verified == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(68.342),
                    border: Border.all(
                      color: const Color(0xFFF4A583).withValues(alpha: 0.6),
                      width: 0.805,
                    ),
                  ),
                  child: Text(
                    'Verified ✓',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF4A583),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    final address = opportunity.address ?? '';
    final distanceStr = Helpers.formatDistance(opportunity.distanceKm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF262222),
            height: 22.286 / 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openMap(),
          child: Container(
            height: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 6.53,
                  offset: Offset(0, 2.82),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/map_placeholder.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFF262222).withValues(alpha: 0.32),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.4),
                    child: Container(
                      width: 30.805,
                      height: 30.805,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x4D10B7A3),
                            blurRadius: 18.483,
                          ),
                        ],
                      ),
                      child: const Icon(
                        IconlyBold.location,
                        size: 15.4,
                        color: Color(0xFFF4A583),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          address,
                          style: GoogleFonts.inter(
                            fontSize: 10.782,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 15.402 / 10.782,
                          ),
                        ),
                        if (distanceStr.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '$distanceStr from you',
                            style: GoogleFonts.inter(
                              fontSize: 9.241,
                              color: Colors.white,
                              height: 12.322 / 9.241,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTags() {
    final tags = opportunity.category.isNotEmpty
        ? opportunity.category
        : ['Volunteering'];

    return Wrap(
      spacing: 5,
      children: tags.map((tag) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 17.455, vertical: 6.545),
          decoration: BoxDecoration(
            color: const Color(0xFF262222).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(108),
            border: Border.all(
              color: const Color(0xFF262222).withValues(alpha: 0.1),
              width: 1.091,
            ),
          ),
          child: Text(
            tag[0].toUpperCase() + tag.substring(1),
            style: GoogleFonts.inter(
              fontSize: 8.727,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _toggleSave() async {
    final provider = context.read<OpportunityProvider>();
    final newSaved = !_isSaved;
    setState(() => _isSaved = newSaved);
    final success = newSaved
        ? await provider.saveOpportunity(opportunity.id)
        : await provider.unsaveOpportunity(opportunity.id);
    if (!success && mounted) {
      setState(() => _isSaved = !newSaved);
    }
  }

  List<Widget> _buildBadgesSection() {
    final badges = _buildBadges();
    if (badges == null) return [];
    return [const SizedBox(height: 15), badges];
  }

  Widget? _buildBadges() {
    final badges = <Widget>[];

    if (opportunity.hasKidsBadge) {
      if (opportunity.kidsOk == true) {
        badges.add(_buildBadgePill(
          text: '\u{1F9D2} Kids welcome',
          bgColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF15803D),
        ));
      } else {
        badges.add(_buildBadgePill(
          text: '\u{1F51E} Adults only',
          bgColor: const Color(0xFFFEF3C7),
          textColor: const Color(0xFF92400E),
        ));
      }
    }

    if (opportunity.acceptsGroups) {
      final groupText = opportunity.maxGroupSize != null
          ? '\u{1F465} Groups welcome (up to ${opportunity.maxGroupSize})'
          : '\u{1F465} Groups welcome';
      badges.add(_buildBadgePill(
        text: groupText,
        bgColor: const Color(0xFFDBEAFE),
        textColor: const Color(0xFF1D4ED8),
      ));
    }

    if (badges.isEmpty) return null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges,
    );
  }

  Widget _buildBadgePill({
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Future<void> _openExternalSignup() async {
    final provider = context.read<OpportunityProvider>();
    final redirectUrl = await provider.trackClick(opportunity.id);
    final urlStr = redirectUrl ?? opportunity.externalUrl;
    if (urlStr != null && urlStr.isNotEmpty) {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _shareOpportunity(BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    final date = Helpers.formatApiDate(opportunity.startDatetime);
    final time = Helpers.formatApiTimeRange(
        opportunity.startDatetime, opportunity.endDatetime);

    Share.share(
      'Check out this volunteer opportunity: ${opportunity.title} by ${opportunity.charityName}!\n\n${opportunity.address ?? ""}\n$date\n$time',
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  Future<void> _openMap() async {
    final query = opportunity.address ?? '';
    if (query.isEmpty) return;
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
