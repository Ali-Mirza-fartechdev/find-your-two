import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/opportunity.dart';
import '../../providers/opportunity_provider.dart';
import '../../utils/helpers.dart';
import 'event_check_in_screen.dart';
import 'opportunity_detail_screen.dart';

class MyOpportunitiesScreen extends StatefulWidget {
  const MyOpportunitiesScreen({super.key});

  @override
  State<MyOpportunitiesScreen> createState() => _MyOpportunitiesScreenState();
}

class _MyOpportunitiesScreenState extends State<MyOpportunitiesScreen> {
  int _selectedTab = 0;
  int? _withdrawingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OpportunityProvider>().fetchMyOpportunities();
    });
  }

  // Tab 0 = Upcoming, Tab 1 = Completed, Tab 2 = Past (missed)
  List<Map<String, dynamic>> _filterByTab(List<Map<String, dynamic>> all) {
    final now = DateTime.now();
    return all.where((item) {
      final opp = item['opportunity'] as Map<String, dynamic>? ?? {};
      final startStr = opp['start_datetime'] as String?;
      final start = Helpers.parseApiDatetime(startStr);
      final isUpcoming = start == null || start.isAfter(now);
      final checkedIn = item['checked_in'] as bool? ?? false;

      switch (_selectedTab) {
        case 0: return isUpcoming;          // Upcoming
        case 1: return !isUpcoming && checkedIn;  // Completed
        case 2: return !isUpcoming && !checkedIn; // Past (missed)
        default: return false;
      }
    }).toList();
  }

  Map<String, int> _getCounts(List<Map<String, dynamic>> all) {
    final now = DateTime.now();
    int upcoming = 0, completed = 0, past = 0;
    for (final item in all) {
      final opp = item['opportunity'] as Map<String, dynamic>? ?? {};
      final startStr = opp['start_datetime'] as String?;
      final start = Helpers.parseApiDatetime(startStr);
      final isUpcoming = start == null || start.isAfter(now);
      final checkedIn = item['checked_in'] as bool? ?? false;

      if (isUpcoming) {
        upcoming++;
      } else if (checkedIn) {
        completed++;
      } else {
        past++;
      }
    }
    return {'upcoming': upcoming, 'completed': completed, 'past': past};
  }

  Future<void> _handleWithdraw(int opportunityId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Withdraw Enrollment',
          style: GoogleFonts.ptSerif(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF262222),
          ),
        ),
        content: Text(
          'Are you sure you want to withdraw from "$title"?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF262222).withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF262222).withValues(alpha: 0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Withdraw',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _withdrawingId = opportunityId);

    final provider = context.read<OpportunityProvider>();
    await provider.withdrawFromOpportunity(opportunityId);

    if (!mounted) return;
    setState(() => _withdrawingId = null);

    if (provider.errorMessage != null) {
      if (mounted) Helpers.showSnackBar(context, message: provider.errorMessage!);
      provider.clearError();
    } else {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          message: 'Enrollment withdrawn successfully',
          backgroundColor: const Color(0xFF15B789),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OpportunityProvider>();
    final allItems = provider.myOpportunities;
    final filtered = _filterByTab(allItems);
    final counts = _getCounts(allItems);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(counts),
                const SizedBox(height: 20),
                _buildToggleTabs(counts),
                const SizedBox(height: 20),
                Expanded(
                  child: provider.isLoading && allItems.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFF4A583)),
                        )
                      : provider.errorMessage != null && allItems.isEmpty
                          ? _buildErrorState(provider)
                          : filtered.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  color: const Color(0xFFF4A583),
                                  onRefresh: () async {
                                    await context
                                        .read<OpportunityProvider>()
                                        .fetchMyOpportunities();
                                  },
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        25, 0, 25, 150),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 15),
                                    itemBuilder: (context, index) {
                                      return _buildOpportunityCard(
                                        item: filtered[index],
                                        isUpcoming: _selectedTab == 0,
                                        isCompleted: _selectedTab == 1,
                                      );
                                    },
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

  Widget _buildHeader(Map<String, int> counts) {
    final upcoming = counts['upcoming'] ?? 0;
    final completed = counts['completed'] ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (Navigator.of(context).canPop()) ...[
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
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Opportunities',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                  height: 26.923 / 18,
                ),
              ),
              Text(
                '$upcoming upcoming · $completed completed',
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

  Widget _buildToggleTabs(Map<String, int> counts) {
    final upcoming = counts['upcoming'] ?? 0;
    final completed = counts['completed'] ?? 0;
    final past = counts['past'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        height: 44.571,
        padding: const EdgeInsets.all(3.71),
        decoration: BoxDecoration(
          color: const Color(0xFF262222).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22.286),
        ),
        child: Row(
          children: [
            _buildTab(0, 'Upcoming ($upcoming)'),
            _buildTab(1, 'Completed ($completed)'),
            _buildTab(2, 'Past ($past)'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17.577),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F1729),
                      blurRadius: 14.062,
                      offset: Offset(0, 3.515),
                      spreadRadius: -1.758,
                    ),
                    BoxShadow(
                      color: Color(0x0F0F1729),
                      blurRadius: 5.273,
                      offset: Offset(0, 1.758),
                      spreadRadius: -1.758,
                    ),
                  ],
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: const Color(0xFF262222),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpportunityCard({
    required Map<String, dynamic> item,
    required bool isUpcoming,
    bool isCompleted = false,
  }) {
    final opp = item['opportunity'] as Map<String, dynamic>? ?? {};
    final oppId = opp['id'] as int? ?? 0;
    final title = opp['title'] as String? ?? '';
    final imageUrl = opp['image_url'] as String?;
    final charityName = opp['charity_name'] as String? ?? '';
    final startDatetime = opp['start_datetime'] as String?;
    final endDatetime = opp['end_datetime'] as String?;
    final address = opp['address'] as String? ?? '';
    final checkedIn = item['checked_in'] as bool? ?? false;
    final status = item['status'] as String? ?? '';
    final partySize = item['party_size'] as int? ?? 1;
    final groupName = item['group_name'] as String?;

    final isWithdrawing = _withdrawingId == oppId;

    return Dismissible(
      key: ValueKey(item['participation_id'] ?? oppId),
      direction: isUpcoming && !isWithdrawing
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        await _handleWithdraw(oppId, title);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(IconlyLight.delete, color: AppColors.error),
      ),
      child: Stack(
        children: [
          Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C000000),
              blurRadius: 19.53,
              offset: Offset(0, 2.82),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                    ),
                    child: SizedBox(
                      width: 88,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => _imagePlaceholder(),
                            )
                          else
                            _imagePlaceholder(),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 16,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0x00FFFFFF),
                                    Color(0x40FFFFFF),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF262222),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(
                                isUpcoming: isUpcoming,
                                checkedIn: checkedIn,
                                status: status,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            charityName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF262222)
                                  .withValues(alpha: 0.62),
                              height: 1.35,
                            ),
                          ),
                          if (partySize > 1) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.group, size: 14, color: Color(0xFFF4A583)),
                                const SizedBox(width: 6),
                                Text(
                                  groupName != null
                                    ? '$groupName ($partySize people)'
                                    : 'Going with ${partySize - 1} other${partySize > 2 ? 's' : ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFF4A583),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  IconlyLight.time_circle,
                                  size: 14,
                                  color: Color(0xFFF4A583),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${Helpers.formatApiDate(startDatetime)} · ${Helpers.formatApiTime(startDatetime)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF262222)
                                        .withValues(alpha: 0.62),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  IconlyLight.location,
                                  size: 14,
                                  color: Color(0xFFF4A583),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  address.split(',').first.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF262222)
                                        .withValues(alpha: 0.62),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(minHeight: 58),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE8EEF3), width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isUpcoming
                              ? (checkedIn
                                  ? 'Checked in'
                                  : 'Ready to volunteer?')
                              : isCompleted
                                  ? 'Completed'
                                  : 'Missed',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF262222)
                                .withValues(alpha: 0.55),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final opportunity = Opportunity(
                              id: oppId,
                              title: title,
                              category: const [],
                              imageUrl: imageUrl,
                              address: address,
                              startDatetime: startDatetime,
                              endDatetime: endDatetime,
                              volunteersNeeded: null,
                              volunteerCount: 0,
                              status: 'active',
                              charity: OpportunityCharity(
                                id: 0,
                                orgName: charityName,
                              ),
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OpportunityDetailScreen(
                                  opportunity: opportunity,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 2),
                            child: Text(
                              'View details',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFF4A583),
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    const Color(0xFFF4A583).withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUpcoming && !checkedIn) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final opportunity = Opportunity(
                          id: oppId,
                          title: title,
                          category: const [],
                          imageUrl: imageUrl,
                          address: address,
                          startDatetime: startDatetime,
                          endDatetime: endDatetime,
                          volunteersNeeded: null,
                          volunteerCount: 0,
                          status: 'active',
                          charity: OpportunityCharity(
                            id: 0,
                            orgName: charityName,
                          ),
                        );
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => EventCheckInScreen(
                              opportunity: opportunity,
                            ),
                          ),
                        );
                        if (result == true && mounted) {
                          context
                              .read<OpportunityProvider>()
                              .fetchMyOpportunities();
                        }
                      },
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15B789).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF15B789).withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              IconlyLight.tick_square,
                              size: 14,
                              color: Color(0xFF15B789),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Check In',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15B789),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _handleWithdraw(oppId, title),
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              IconlyLight.close_square,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Withdraw',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      if (isWithdrawing)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFF4A583),
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isUpcoming,
    required bool checkedIn,
    required String status,
  }) {
    final Color bgColor;
    final Color textColor;
    final String label;

    if (checkedIn) {
      bgColor = const Color(0x1A15B789);
      textColor = const Color(0xFF15B789);
      label = 'Checked In';
    } else if (!isUpcoming) {
      bgColor = const Color(0x1A15B789);
      textColor = const Color(0xFF15B789);
      label = 'Completed';
    } else {
      bgColor = const Color(0x1A2469FF);
      textColor = const Color(0xFF2469FF);
      label = status == 'confirmed' ? 'Confirmed' : 'Registered';
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFEEF2F6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          IconlyLight.image,
          size: 26,
          color: const Color(0xFF262222).withValues(alpha: 0.12),
        ),
      ),
    );
  }

  Widget _buildErrorState(OpportunityProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IconlyLight.danger, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF262222).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  context.read<OpportunityProvider>().fetchMyOpportunities(),
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF4A583),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            IconlyLight.calendar,
            size: 48,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedTab == 0
                ? 'No upcoming opportunities'
                : 'No past opportunities',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF262222),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedTab == 0
                ? 'Enroll in an opportunity to see it here'
                : _selectedTab == 1
                    ? 'Events you checked into will appear here'
                    : 'Past events you missed will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
