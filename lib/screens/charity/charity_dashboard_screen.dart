import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/charity_provider.dart';
import '../../services/charity_service.dart';
import '../../utils/helpers.dart';
import 'charity_map_view_screen.dart';
import '../volunteer/volunteer_shell.dart';
import 'charity_opportunity_detail_screen.dart';
import 'charity_profile_screen.dart';
import 'create_opportunity_screen.dart';

class CharityDashboardScreen extends StatefulWidget {
  const CharityDashboardScreen({super.key});

  @override
  State<CharityDashboardScreen> createState() => _CharityDashboardScreenState();
}

class _CharityDashboardScreenState extends State<CharityDashboardScreen> {
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<CharityProvider>();
    await Future.wait([
      provider.fetchDashboard(),
      provider.fetchProfile(),
      provider.fetchCharityOpportunities(),
    ]);
    if (mounted && _isInitialLoad) {
      setState(() => _isInitialLoad = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<CharityProvider>(
        builder: (context, provider, _) {
          // Initial loading — show spinner until ALL parallel fetches complete
          if (_isInitialLoad) {
            // Check if we already have an early result (no profile / error)
            if (provider.noCharityProfile) {
              return Stack(
                children: [
                  _buildBgBlob(),
                  _buildNoProfileState(context),
                ],
              );
            }
            return Stack(
              children: [
                _buildBgBlob(),
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFF4A583),
                  ),
                ),
              ],
            );
          }

          // No charity profile state
          if (provider.noCharityProfile) {
            return Stack(
              children: [
                _buildBgBlob(),
                _buildNoProfileState(context),
              ],
            );
          }

          // Error state (dashboard fetch failed)
          if (provider.dashboard == null && provider.dashboardError != null) {
            return Stack(
              children: [
                _buildBgBlob(),
                _buildErrorState(context, provider),
              ],
            );
          }

          // Dashboard loaded — show content
          return Stack(
            children: [
              _buildBgBlob(),
              RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color(0xFFF4A583),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildDarkHeader(context, provider),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildParticipationChart(provider.dashboard),
                            const SizedBox(height: 20),
                            _buildStatsRow(provider.dashboard),
                            const SizedBox(height: 20),
                            _buildCreateButton(context),
                            const SizedBox(height: 20),
                            _buildOpportunitySections(context, provider),
                            const SizedBox(height: 150),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Background Blob ──────────────────────────────────────────────

  Widget _buildBgBlob() {
    return Positioned(
      left: -295,
      top: -261,
      width: 979,
      height: 1499,
      child: SvgPicture.asset(
        'assets/images/home_bg_blob.svg',
        fit: BoxFit.fill,
      ),
    );
  }

  // ─── No Charity Profile State ─────────────────────────────────────

  Widget _buildNoProfileState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                IconlyLight.category,
                size: 36,
                color: Color(0xFFF4A583),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Set Up Your Charity',
              style: GoogleFonts.ptSerif(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Create your charity profile to start posting opportunities and managing volunteers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF262222).withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const CharityProfileScreen(
                      isCreateMode: true,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  _loadData();
                }
              },
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
                    const Icon(IconlyLight.plus, size: 18.5, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Create Charity Profile',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  // ─── Error State ──────────────────────────────────────────────────

  Widget _buildErrorState(BuildContext context, CharityProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconlyLight.info_circle,
              size: 48,
              color: const Color(0xFF262222).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.dashboardError ?? 'Unable to load dashboard data.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF262222).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _loadData(),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A583),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Center(
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dark Header ──────────────────────────────────────────────────

  Widget _buildDarkHeader(BuildContext context, CharityProvider provider) {
    final orgName = provider.profile?.orgName ??
        provider.dashboard?.orgName ??
        'Your Organization';
    final logoUrl = provider.profile?.logoUrl;

    return Container(
      width: double.infinity,
      height: 170 + MediaQuery.of(context).padding.top,
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
          // Top bar: logo + greeting + charity mode + map
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo-1.png',
                  width: 20,
                  height: 24,
                  fit: BoxFit.contain,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(width: 7),
                Text(
                  'Good Morning',
                  style: GoogleFonts.inter(
                    fontSize: 12.26,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Charity Mode toggle → switch to volunteer
                GestureDetector(
                  onTap: () async {
                    await context
                        .read<AuthProvider>()
                        .switchMode(mode: 'volunteer');
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true)
                          .pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const VolunteerShell(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(58),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 0.685,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/volunteer_mode.svg',
                          width: 12,
                          height: 7,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          'Charity Mode',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Map icon
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CharityMapViewScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 0.933,
                      ),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/map_view.svg',
                        width: 14.4,
                        height: 14.4,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Organization info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                // Org avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 0.628,
                    ),
                  ),
                  child: ClipOval(
                    child: logoUrl != null && logoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: logoUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: Icon(
                                IconlyLight.category,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(
                                IconlyLight.category,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              IconlyLight.category,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orgName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ptSerif(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 28.846 / 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Charity Dashboard Overview',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Volunteer Participation Chart ────────────────────────────────

  Widget _buildParticipationChart(CharityDashboardData? dashboard) {
    final chartData = dashboard?.participationChart ?? [];

    // Extract labels and values
    final labels = <String>[];
    final values = <double>[];
    for (final point in chartData) {
      labels.add(point['label']?.toString() ?? '');
      final val = point['value'];
      if (val is num) {
        values.add(val.toDouble());
      } else {
        values.add(0);
      }
    }

    final maxVal = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    // Calculate trend percentage if we have at least 2 points
    String trendText = '';
    if (values.length >= 2) {
      final prev = values[values.length - 2];
      final curr = values[values.length - 1];
      if (prev > 0) {
        final pct = ((curr - prev) / prev * 100).round();
        trendText = pct >= 0 ? '↑ +$pct%' : '↓ $pct%';
      }
    }

    return Container(
      height: 189,
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
          Row(
            children: [
              const Icon(
                IconlyLight.chart,
                size: 16.7,
                color: Color(0xFFF4A583),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volunteer Participation',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                  ),
                  Text(
                    'Monthly trend',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF262222).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (trendText.isNotEmpty)
                Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262222).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(68),
                    border: Border.all(
                      color: const Color(0xFF262222).withValues(alpha: 0.6),
                      width: 0.805,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      trendText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF262222),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          // Line chart
          Expanded(
            child: values.isEmpty
                ? Center(
                    child: Text(
                      'No data yet',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF262222).withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _LineChartPainter(
                      values: values,
                      maxVal: maxVal,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          // Month labels
          if (labels.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: labels
                  .map(
                    (m) => Text(
                      m,
                      style: GoogleFonts.inter(
                        fontSize: 9.265,
                        color:
                            const Color(0xFF262222).withValues(alpha: 0.5),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────

  Widget _buildStatsRow(CharityDashboardData? dashboard) {
    final totalVolunteers = dashboard?.totalVolunteers ?? 0;
    final activePosts = dashboard?.activePosts ?? 0;
    final upcoming = dashboard?.upcoming ?? 0;
    final peopleSent = dashboard?.peopleSent ?? 0;

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              IconlyLight.user,
              _formatStatNumber(totalVolunteers),
              'Total People',
            ),
            const SizedBox(width: 11),
            _buildStatCard(
              IconlyLight.document,
              activePosts.toString(),
              'Active Posts',
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            _buildStatCard(
              IconlyLight.calendar,
              upcoming.toString(),
              'Upcoming',
            ),
            const SizedBox(width: 11),
            _buildStatCard(
              IconlyLight.send,
              _formatStatNumber(peopleSent),
              'People Sent',
            ),
          ],
        ),
      ],
    );
  }

  String _formatStatNumber(int number) {
    if (number >= 1000) {
      final k = number / 1000;
      return k == k.roundToDouble()
          ? '${k.round()},${(number % 1000).toString().padLeft(3, '0').substring(0, 3)}'
          : '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        height: 108,
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
            Container(
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: const Color(0xFFF4A583)),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18.5,
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

  // ─── Create Opportunity Button ────────────────────────────────────

  Widget _buildCreateButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const CreateOpportunityScreen(),
          ),
        );
        if (result == true && mounted) {
          context.read<CharityProvider>().fetchDashboard();
        }
      },
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
            const Icon(IconlyLight.plus, size: 18.5, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Create Opportunity',
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

  // ─── Active Opportunities ─────────────────────────────────────────

  Widget _buildOpportunitySections(BuildContext context, CharityProvider provider) {
    final allOpps = provider.charityOpportunities ?? [];
    final activeOpps = allOpps.where((o) => o['status'] == 'active').map((o) => Opportunity.fromJson(o)).toList();
    final draftOpps = allOpps.where((o) => o['status'] == 'draft').map((o) => Opportunity.fromJson(o)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Active Section ──────────────────────────────
        _buildSectionHeader(
          context,
          title: 'Active Opportunities',
          count: activeOpps.length,
          allOpps: activeOpps,
        ),
        const SizedBox(height: 15),
        if (activeOpps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No active opportunities yet.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF262222).withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          ...activeOpps.take(3).map(
            (opp) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: _buildOpportunityCard(context, opp, isDraft: false),
            ),
          ),

        // ─── Drafts Section ──────────────────────────────
        if (draftOpps.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildSectionHeader(
            context,
            title: 'Drafts',
            count: draftOpps.length,
            allOpps: draftOpps,
          ),
          const SizedBox(height: 15),
          ...draftOpps.take(3).map(
            (opp) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: _buildOpportunityCard(context, opp, isDraft: true),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required List<Opportunity> allOpps,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF262222)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF262222).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF262222).withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
        if (count > 3)
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _AllActiveOpportunitiesScreen(
                    title: title,
                    opportunities: allOpps,
                    onReturn: () {
                      if (mounted) _loadData();
                    },
                  ),
                ),
              );
            },
            child: Text(
              'View all \u2192',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFF4A583)),
            ),
          ),
      ],
    );
  }

  Widget _buildOpportunityCard(BuildContext context, Opportunity opp, {bool isDraft = false}) {
    final dateStr = Helpers.formatApiDate(opp.startDatetime);
    final timeStr = Helpers.formatApiTime(opp.startDatetime);
    final progress = opp.isUncapped
        ? 0.0
        : (opp.volunteersNeeded! > 0
            ? (opp.volunteerCount / opp.volunteersNeeded!).clamp(0.0, 1.0)
            : 0.0);

    return GestureDetector(
      onTap: () async {
        if (isDraft) {
          // Open edit screen for drafts
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => CreateOpportunityScreen(opportunity: opp),
            ),
          );
          if (result == true && mounted) _loadData();
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CharityOpportunityDetailScreen(opportunity: opp),
            ),
          );
          if (mounted) _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isDraft ? const Color(0xFFFFF8F5) : Colors.white,
          border: isDraft ? Border.all(color: const Color(0xFFF4A583).withValues(alpha: 0.2), width: 1) : null,
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
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                width: 52,
                height: 52,
                child: opp.imageUrl != null && opp.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: opp.imageUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                          child: const Icon(
                            IconlyLight.image,
                            size: 20,
                            color: Color(0xFFF4A583),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                          child: const Icon(
                            IconlyLight.image,
                            size: 20,
                            color: Color(0xFFF4A583),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                        child: const Icon(
                          IconlyLight.image,
                          size: 20,
                          color: Color(0xFFF4A583),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 11),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          opp.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF262222),
                          ),
                        ),
                      ),
                      if (isDraft) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4A583).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Draft',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF4A583),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateStr \u00b7 $timeStr',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF262222).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar + count
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9264),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3.7,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                              Color(0xFFF4A583),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        opp.isUncapped
                            ? '${opp.volunteerCount}'
                            : '${opp.volunteerCount}/${opp.volunteersNeeded}',
                        style: GoogleFonts.inter(
                          fontSize: 9.265,
                          color: const Color(0xFF262222)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action icons
            Column(
              children: [
                Icon(
                  IconlyLight.chart,
                  size: 13,
                  color: const Color(0xFFF4A583),
                ),
                const SizedBox(height: 14),
                Icon(
                  IconlyLight.arrow_right_2,
                  size: 13,
                  color: const Color(0xFF262222).withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Line Chart Painter ──────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxVal;

  _LineChartPainter({required this.values, required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final dotPaint = Paint()..color = const Color(0xFFF4A583);

    // Single data point — draw dot + horizontal line + gradient fill
    if (values.length == 1) {
      final y = size.height - (values[0] / maxVal * size.height);
      final center = Offset(size.width / 2, y);

      // Fill gradient below the line
      final fillPath = Path()
        ..addRect(Rect.fromLTRB(0, y, size.width, size.height));
      final fillPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x40F4A583), Color(0x00F4A583)],
        ).createShader(Rect.fromLTRB(0, y, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);

      // Horizontal line
      final linePaint = Paint()
        ..color = const Color(0xFFF4A583)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

      // Dot with white center ring
      canvas.drawCircle(center, 6, dotPaint);
      canvas.drawCircle(center, 3, Paint()..color = Colors.white);
      return;
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - (values[i] / maxVal * size.height);
      points.add(Offset(x, y));
    }

    // Fill gradient
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x40F4A583), Color(0x00F4A583)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFFF4A583)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cx = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.maxVal != maxVal;
  }
}

// ─── All Active Opportunities Screen ─────────────────────────────────

class _AllActiveOpportunitiesScreen extends StatelessWidget {
  final List<Opportunity> opportunities;
  final VoidCallback? onReturn;
  final String title;

  const _AllActiveOpportunitiesScreen({
    required this.opportunities,
    this.onReturn,
    this.title = 'Active Opportunities',
  });

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
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 16, 25, 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          onReturn?.call();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF262222)
                                .withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF262222)
                                  .withValues(alpha: 0.6),
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
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF262222),
                            ),
                          ),
                          Text(
                            '${opportunities.length} opportunities',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF262222),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(25, 0, 25, 40),
                    itemCount: opportunities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final opp = opportunities[index];
                      final dateStr =
                          Helpers.formatApiDate(opp.startDatetime);
                      final timeStr =
                          Helpers.formatApiTime(opp.startDatetime);
                      final progress = (opp.volunteersNeeded ?? 0) > 0
                          ? (opp.volunteerCount / opp.volunteersNeeded!)
                              .clamp(0.0, 1.0)
                          : 0.0;

                      return GestureDetector(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CharityOpportunityDetailScreen(
                                opportunity: opp,
                              ),
                            ),
                          );
                          onReturn?.call();
                        },
                        child: Container(
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
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: opp.imageUrl != null &&
                                          opp.imageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: opp.imageUrl!,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            color: const Color(0xFFF4A583)
                                                .withValues(alpha: 0.1),
                                            child: const Icon(
                                              IconlyLight.image,
                                              size: 20,
                                              color: Color(0xFFF4A583),
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) =>
                                              Container(
                                            color: const Color(0xFFF4A583)
                                                .withValues(alpha: 0.1),
                                            child: const Icon(
                                              IconlyLight.image,
                                              size: 20,
                                              color: Color(0xFFF4A583),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: const Color(0xFFF4A583)
                                              .withValues(alpha: 0.1),
                                          child: const Icon(
                                            IconlyLight.image,
                                            size: 20,
                                            color: Color(0xFFF4A583),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
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
                                    Text(
                                      '$dateStr \u00b7 $timeStr',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF262222)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(9264),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 3.7,
                                              backgroundColor:
                                                  const Color(0xFFF1F5F9),
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Color(0xFFF4A583)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          opp.isUncapped
                                              ? '${opp.volunteerCount}'
                                              : '${opp.volunteerCount}/${opp.volunteersNeeded}',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.265,
                                            color: const Color(0xFF262222)
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
