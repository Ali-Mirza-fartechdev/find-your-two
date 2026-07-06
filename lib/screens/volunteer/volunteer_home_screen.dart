import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../models/opportunity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../utils/category_utils.dart';
import '../../widgets/common/opportunity_card_small.dart';
import '../../widgets/common/opportunity_card_full.dart';
import '../charity/charity_shell.dart';
import '../charity/location_picker_screen.dart';
import 'all_opportunities_screen.dart';
import 'map_view_screen.dart';
import 'enrollment_screen.dart';
import 'opportunity_detail_screen.dart';

class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key});

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen> {
  final Set<String> _selectedCategories = {};
  bool _kidsOkFilter = false;
  bool _acceptsGroupsFilter = false;
  final Set<String> _selectedDays = {};
  final Set<String> _selectedTimes = {};

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  bool _initialLoadDone = false;
  bool _initialCheckComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auto-set kids_ok filter from user preference
      final user = context.read<AuthProvider>().user;
      if (user?.kidsOkPreferred == true) {
        setState(() => _kidsOkFilter = true);
      }
      _performInitialLoad();
    });
  }

  Future<void> _performInitialLoad() async {
    final provider = context.read<OpportunityProvider>();
    await provider.fetchOpportunities(refresh: true);
    if (!mounted) return;
    if (provider.opportunities.isNotEmpty) {
      _initialLoadDone = true;
    }
    setState(() => _initialCheckComplete = true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = _selectedCategories.length;
    if (_kidsOkFilter) count++;
    if (_acceptsGroupsFilter) count++;
    count += _selectedDays.length;
    count += _selectedTimes.length;
    return count;
  }

  void _loadOpportunities({bool refresh = false}) {
    final search = _searchController.text.trim().isNotEmpty
        ? _searchController.text.trim()
        : null;

    context.read<OpportunityProvider>().fetchOpportunities(
          refresh: refresh,
          categories: _selectedCategories.isNotEmpty
              ? _selectedCategories.toList()
              : null,
          search: search,
          kidsOk: _kidsOkFilter ? true : null,
          acceptsGroups: _acceptsGroupsFilter ? true : null,
          daysOfWeek:
              _selectedDays.isNotEmpty ? _selectedDays.toList() : null,
          timesOfDay:
              _selectedTimes.isNotEmpty ? _selectedTimes.toList() : null,
        );
  }

  void _onSearchChanged(String value) {
    setState(() {}); // update clear button visibility
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadOpportunities(refresh: true);
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _kidsOkFilter = false;
      _acceptsGroupsFilter = false;
      _selectedDays.clear();
      _selectedTimes.clear();
    });
    _loadOpportunities(refresh: true);
  }

  void _showFilterBottomSheet() {
    // Temp copies so user can cancel
    final tempDays = Set<String>.from(_selectedDays);
    final tempTimes = Set<String>.from(_selectedTimes);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            const days = [
              ('Sun', 'sun'),
              ('Mon', 'mon'),
              ('Tue', 'tue'),
              ('Wed', 'wed'),
              ('Thu', 'thu'),
              ('Fri', 'fri'),
              ('Sat', 'sat'),
            ];
            const times = [
              ('Morning', 'morning'),
              ('Afternoon', 'afternoon'),
              ('Evening', 'evening'),
            ];

            return Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF262222).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Days of Week',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF262222),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: days.map((d) {
                      final isSelected = tempDays.contains(d.$2);
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            isSelected
                                ? tempDays.remove(d.$2)
                                : tempDays.add(d.$2);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF4A583)
                                : const Color(0xFF262222)
                                    .withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(108),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: const Color(0xFF262222)
                                        .withValues(alpha: 0.1),
                                    width: 1.1,
                                  ),
                          ),
                          child: Text(
                            d.$1,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF262222)
                                      .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Time of Day',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF262222),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: times.map((t) {
                      final isSelected = tempTimes.contains(t.$2);
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            isSelected
                                ? tempTimes.remove(t.$2)
                                : tempTimes.add(t.$2);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF4A583)
                                : const Color(0xFF262222)
                                    .withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(108),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: const Color(0xFF262222)
                                        .withValues(alpha: 0.1),
                                    width: 1.1,
                                  ),
                          ),
                          child: Text(
                            t.$1,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF262222)
                                      .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedDays
                            ..clear()
                            ..addAll(tempDays);
                          _selectedTimes
                            ..clear()
                            ..addAll(tempTimes);
                        });
                        Navigator.of(ctx).pop();
                        _loadOpportunities(refresh: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4A583),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OpportunityProvider>();

    if (!_initialLoadDone && provider.opportunities.isNotEmpty) {
      _initialLoadDone = true;
    }

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
            child: !_initialCheckComplete
                ? _buildInitialLoading()
                : _initialLoadDone
                    ? _buildPopulatedContent(provider)
                    : _buildEmptyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildLocationBar(),
        _buildTitleSection(),
        _buildSearchBar(),
        const SizedBox(height: 15),
        _buildDivider(),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFF4A583)),
          ),
        ),
      ],
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────

  Widget _buildEmptyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildLocationBar(),
        _buildTitleSection(),
        _buildSearchBar(),
        const SizedBox(height: 15),
        _buildDivider(),
        const SizedBox(height: 60),
        _buildFindFirstOpportunity(),
      ],
    );
  }

  // ─── POPULATED STATE ──────────────────────────────────────────────

  Widget _buildPopulatedContent(OpportunityProvider provider) {
    return RefreshIndicator(
      color: const Color(0xFFF4A583),
      onRefresh: () async {
        _loadOpportunities(refresh: true);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildLocationBar()),
          SliverToBoxAdapter(child: _buildTitleSection()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
          SliverToBoxAdapter(child: _buildDivider()),
          SliverToBoxAdapter(child: _buildFilterChips()),
          SliverToBoxAdapter(
              child: _buildRecommendedSection(provider.opportunities)),
          SliverToBoxAdapter(
              child: _buildAllOpportunitiesHeader(provider)),

          if (provider.isLoading && provider.opportunities.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFF4A583)),
                ),
              ),
            )
          else if (provider.errorMessage != null &&
              provider.opportunities.isEmpty)
            SliverToBoxAdapter(child: _buildErrorState(provider))
          else if (provider.opportunities.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyResults())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final opp = provider.opportunities[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: OpportunityCardFull(
                      opportunity: opp,
                      onTap: () => _navigateToDetail(opp),
                      onEnroll: () => _navigateToEnrollment(opp),
                      onSave: () => _toggleSave(opp),
                    ),
                  );
                }, childCount: provider.opportunities.length),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ─── SHARED WIDGETS ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo-1.png',
            width: 20,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 7),
          Text(
            'Good Morning',
            style: GoogleFonts.inter(
              fontSize: 12.26,
              color: const Color(0xFF262222),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _navigateToCharityMode,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF262222).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(58),
                border: Border.all(
                  color: const Color(0xFF262222).withValues(alpha: 0.6),
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
                  ),
                  const SizedBox(width: 3.5),
                  Text(
                    'Volunteer Mode',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF262222),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _navigateToMapView,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF262222).withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF262222).withValues(alpha: 0.6),
                  width: 0.933,
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/map_view.svg',
                  width: 14.4,
                  height: 14.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBar() {
    final provider = context.watch<OpportunityProvider>();
    final address = provider.userAddress ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
      child: GestureDetector(
        onTap: _changeLocation,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4A583).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: const Color(0xFFF4A583).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(IconlyBold.location, size: 14, color: Color(0xFFF4A583)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address.isNotEmpty ? address : 'Set location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF262222),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Change',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF4A583),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeLocation() async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen(bottomOffset: 100)),
    );

    if (result != null && mounted) {
      final provider = context.read<OpportunityProvider>();
      provider.setUserLocation(
        latitude: result.latitude,
        longitude: result.longitude,
        address: result.address,
      );

      // Save location to user profile
      context.read<AuthProvider>().updateProfile(
        latitude: result.latitude,
        longitude: result.longitude,
        location: result.address,
      );

      _loadOpportunities(refresh: true);
    }
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 8, 25, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find your Two',
            style: GoogleFonts.ptSerif(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
              letterSpacing: -0.2,
              height: 35 / 10,
            ),
          ),
          RichText(
            text: TextSpan(
              style: GoogleFonts.ptSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
                letterSpacing: -0.4,
              ),
              children: [
                TextSpan(
                  text: 'Two',
                  style: GoogleFonts.ptSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF262222),
                    height: 20 / 20,
                  ),
                ),
                TextSpan(
                  text: ' Hours Can Change The World',
                  style: GoogleFonts.ptSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF262222),
                    height: 35 / 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF262222).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: const Color(0xFF262222).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 18),
            SvgPicture.asset('assets/icons/search.svg', width: 17, height: 17),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                cursorColor: const Color(0xFFF4A583),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF262222),
                ),
                decoration: InputDecoration(
                  hintText: 'Search opportunities...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF262222).withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onTap: () {
                  if (!_initialLoadDone) {
                    setState(() => _initialLoadDone = true);
                  }
                },
                onChanged: _onSearchChanged,
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _loadOpportunities(refresh: true);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    IconlyLight.close_square,
                    size: 16,
                    color: const Color(0xFF262222).withValues(alpha: 0.4),
                  ),
                ),
              )
            else
              const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Divider(
        color: const Color(0xFF262222).withValues(alpha: 0.1),
        height: 1,
      ),
    );
  }

  Widget _buildFindFirstOpportunity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _initialLoadDone = true;
            });
            _loadOpportunities(refresh: true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF4A583),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
            ),
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            'Find Your First Opportunity',
            style: GoogleFonts.ptSerif(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    // Categories: skip 'All' (index 0), use the rest
    final categories = CategoryUtils.filterTags.sublist(1);

    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category chips (multi-select) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: categories.map((cat) {
                final key = cat.toLowerCase();
                final isSelected = _selectedCategories.contains(key);
                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isSelected
                            ? _selectedCategories.remove(key)
                            : _selectedCategories.add(key);
                      });
                      _loadOpportunities(refresh: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF4A583)
                            : const Color(0xFF262222)
                                .withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(108),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: const Color(0xFF262222)
                                    .withValues(alpha: 0.1),
                                width: 1.1,
                              ),
                      ),
                      child: Text(
                        cat,
                        style: isSelected
                            ? GoogleFonts.openSans(
                                fontSize: 8.7,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )
                            : GoogleFonts.inter(
                                fontSize: 8.7,
                                color: const Color(0xFF262222)
                                    .withValues(alpha: 0.5),
                              ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // ── Toggle chips + Filters button + Clear all ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                // Kids friendly toggle
                GestureDetector(
                  onTap: () {
                    setState(() => _kidsOkFilter = !_kidsOkFilter);
                    _loadOpportunities(refresh: true);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kidsOkFilter
                          ? const Color(0xFFF4A583)
                          : const Color(0xFF262222).withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(108),
                      border: _kidsOkFilter
                          ? null
                          : Border.all(
                              color: const Color(0xFF262222)
                                  .withValues(alpha: 0.1),
                              width: 1.1,
                            ),
                    ),
                    child: Text(
                      '🧒 Kids friendly',
                      style: _kidsOkFilter
                          ? GoogleFonts.openSans(
                              fontSize: 8.7,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )
                          : GoogleFonts.inter(
                              fontSize: 8.7,
                              color: const Color(0xFF262222)
                                  .withValues(alpha: 0.5),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                // Groups toggle
                GestureDetector(
                  onTap: () {
                    setState(
                        () => _acceptsGroupsFilter = !_acceptsGroupsFilter);
                    _loadOpportunities(refresh: true);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _acceptsGroupsFilter
                          ? const Color(0xFFF4A583)
                          : const Color(0xFF262222).withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(108),
                      border: _acceptsGroupsFilter
                          ? null
                          : Border.all(
                              color: const Color(0xFF262222)
                                  .withValues(alpha: 0.1),
                              width: 1.1,
                            ),
                    ),
                    child: Text(
                      '👥 Groups',
                      style: _acceptsGroupsFilter
                          ? GoogleFonts.openSans(
                              fontSize: 8.7,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )
                          : GoogleFonts.inter(
                              fontSize: 8.7,
                              color: const Color(0xFF262222)
                                  .withValues(alpha: 0.5),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                // Filters button with badge
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_selectedDays.isNotEmpty ||
                              _selectedTimes.isNotEmpty)
                          ? const Color(0xFFF4A583).withValues(alpha: 0.12)
                          : const Color(0xFF262222).withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(108),
                      border: Border.all(
                        color: (_selectedDays.isNotEmpty ||
                                _selectedTimes.isNotEmpty)
                            ? const Color(0xFFF4A583).withValues(alpha: 0.4)
                            : const Color(0xFF262222).withValues(alpha: 0.1),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconlyLight.filter,
                          size: 12,
                          color: (_selectedDays.isNotEmpty ||
                                  _selectedTimes.isNotEmpty)
                              ? const Color(0xFFF4A583)
                              : const Color(0xFF262222).withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filters',
                          style: GoogleFonts.inter(
                            fontSize: 8.7,
                            fontWeight: (_selectedDays.isNotEmpty ||
                                    _selectedTimes.isNotEmpty)
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: (_selectedDays.isNotEmpty ||
                                    _selectedTimes.isNotEmpty)
                                ? const Color(0xFFF4A583)
                                : const Color(0xFF262222)
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                        if (_selectedDays.length + _selectedTimes.length >
                            0) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF4A583),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${_selectedDays.length + _selectedTimes.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Clear all
                if (_activeFilterCount > 0)
                  GestureDetector(
                    onTap: _clearAllFilters,
                    child: Text(
                      'Clear all',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF4A583),
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

  Widget _buildRecommendedSection(List<Opportunity> opportunities) {
    if (opportunities.isEmpty) return const SizedBox.shrink();
    final recommended =
        opportunities.take(6).toList();

    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended for you',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AllOpportunitiesScreen(),
                    ),
                  );
                  if (mounted) _loadOpportunities(refresh: true);
                },
                child: Text(
                  'See all',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF4A583),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 225,
          child: Stack(
            children: [
              ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 7),
                itemCount: recommended.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return OpportunityCardSmall(
                    opportunity: recommended[index],
                    onTap: () => _navigateToDetail(recommended[index]),
                  );
                },
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 54,
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0x00FFFFFF), Colors.white],
                        stops: [0.0882, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildAllOpportunitiesHeader(OpportunityProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 12, 25, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'All Opportunities',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
            ),
          ),
          Text(
            '${provider.total} found',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(OpportunityProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
      child: Column(
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
            onPressed: () => _loadOpportunities(refresh: true),
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
    );
  }

  Widget _buildEmptyResults() {
    final provider = context.read<OpportunityProvider>();
    final isNearby = provider.hasLocation;
    final address = provider.userAddress ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
      child: Column(
        children: [
          Icon(
            isNearby ? IconlyLight.location : IconlyLight.search,
            size: 48,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            isNearby
                ? 'No opportunities in your area'
                : 'No opportunities found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF262222),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isNearby
                ? 'There are no active volunteer opportunities near ${address.isNotEmpty ? address : "your location"} right now. Check back later!'
                : 'Try a different search or filter',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SAVE ────────────────────────────────────────────────────────

  void _toggleSave(Opportunity opp) {
    final provider = context.read<OpportunityProvider>();
    if (opp.isSaved) {
      provider.unsaveOpportunity(opp.id);
    } else {
      provider.saveOpportunity(opp.id);
    }
  }

  // ─── NAVIGATION ───────────────────────────────────────────────────

  void _navigateToDetail(Opportunity opp) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OpportunityDetailScreen(opportunity: opp),
      ),
    );
  }

  void _navigateToEnrollment(Opportunity opp) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnrollmentScreen(opportunity: opp),
      ),
    );
  }

  void _navigateToCharityMode() async {
    await context.read<AuthProvider>().switchMode(mode: 'charity');
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(builder: (_) => const CharityShell()),
    );
  }

  void _navigateToMapView() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MapViewScreen()),
    );
  }
}
