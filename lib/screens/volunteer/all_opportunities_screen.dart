import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../models/opportunity.dart';
import '../../providers/opportunity_provider.dart';
import '../../utils/category_utils.dart';
import '../../widgets/common/opportunity_card_full.dart';
import 'enrollment_screen.dart';
import 'opportunity_detail_screen.dart';

class AllOpportunitiesScreen extends StatefulWidget {
  const AllOpportunitiesScreen({super.key});

  @override
  State<AllOpportunitiesScreen> createState() => _AllOpportunitiesScreenState();
}

class _AllOpportunitiesScreenState extends State<AllOpportunitiesScreen> {
  final Set<String> _selectedCategories = {};
  bool _kidsOkFilter = false;
  bool _acceptsGroupsFilter = false;
  final Set<String> _selectedDays = {};
  final Set<String> _selectedTimes = {};

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOpportunities(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<OpportunityProvider>();
      if (!provider.isLoading && provider.hasMore) {
        _loadOpportunities();
      }
    }
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
    setState(() {});
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFF4A583),
          onRefresh: () async {
            _loadOpportunities(refresh: true);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              const SliverToBoxAdapter(child: SizedBox(height: 15)),
              SliverToBoxAdapter(child: _buildFilterChips()),
              const SliverToBoxAdapter(child: SizedBox(height: 15)),
              SliverToBoxAdapter(child: _buildResultsHeader(provider)),

              if (provider.isLoading && provider.opportunities.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFF4A583)),
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                      },
                      childCount: provider.opportunities.length,
                    ),
                  ),
                ),

              if (provider.isLoading && provider.opportunities.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFF4A583)),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 16, 25, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              IconlyLight.arrow_left,
              size: 18,
              color: Color(0xFF262222),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'All Opportunities',
            style: GoogleFonts.ptSerif(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
            ),
          ),
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
                onChanged: _onSearchChanged,
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {});
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

  Widget _buildFilterChips() {
    final categories = CategoryUtils.filterTags.sublist(1);

    return Column(
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
                          : const Color(0xFF262222).withValues(alpha: 0.03),
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
                  setState(() => _acceptsGroupsFilter = !_acceptsGroupsFilter);
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
    );
  }

  Widget _buildResultsHeader(OpportunityProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Results',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
      child: Column(
        children: [
          const Icon(IconlyLight.search, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            'No opportunities found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF262222),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search or filter',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSave(Opportunity opp) {
    final provider = context.read<OpportunityProvider>();
    if (opp.isSaved) {
      provider.unsaveOpportunity(opp.id);
    } else {
      provider.saveOpportunity(opp.id);
    }
  }

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
}
