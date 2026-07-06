import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../models/opportunity.dart';
import '../../providers/opportunity_provider.dart';
import '../../widgets/common/opportunity_card_full.dart';
import 'enrollment_screen.dart';
import 'opportunity_detail_screen.dart';

class SavedOpportunitiesScreen extends StatefulWidget {
  const SavedOpportunitiesScreen({super.key});

  @override
  State<SavedOpportunitiesScreen> createState() =>
      _SavedOpportunitiesScreenState();
}

class _SavedOpportunitiesScreenState extends State<SavedOpportunitiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OpportunityProvider>().fetchSavedOpportunities();
    });
  }

  void _toggleSave(Opportunity opp) {
    final provider = context.read<OpportunityProvider>();
    if (opp.isSaved) {
      provider.unsaveOpportunity(opp.id);
    } else {
      provider.saveOpportunity(opp.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OpportunityProvider>();
    final saved = provider.savedOpportunities;

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
                _buildHeader(),
                const SizedBox(height: 20),
                Expanded(
                  child: provider.isLoading && saved.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF4A583),
                          ),
                        )
                      : saved.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: const Color(0xFFF4A583),
                              onRefresh: () async {
                                await provider.fetchSavedOpportunities();
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    25, 0, 25, 150),
                                itemCount: saved.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 15),
                                itemBuilder: (context, index) {
                                  final opp = saved[index];
                                  return OpportunityCardFull(
                                    opportunity: opp,
                                    onTap: () => _navigateToDetail(opp),
                                    onEnroll: () =>
                                        _navigateToEnrollment(opp),
                                    onSave: () => _toggleSave(opp),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
      child: Row(
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
              child: const Center(
                child: Icon(IconlyLight.arrow_left,
                    size: 16, color: Color(0xFF262222)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saved Opportunities',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                  height: 26.923 / 18,
                ),
              ),
              Text(
                'Opportunities you saved for later',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            IconlyLight.bookmark,
            size: 48,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            'No saved opportunities',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF262222),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the heart icon on any opportunity to save it here',
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
