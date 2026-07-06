import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../models/opportunity.dart';
import '../../utils/category_utils.dart';
import '../../utils/helpers.dart';

class OpportunityCardFull extends StatelessWidget {
  final Opportunity opportunity;
  final VoidCallback? onTap;
  final VoidCallback? onEnroll;
  final VoidCallback? onSave;

  const OpportunityCardFull({
    super.key,
    required this.opportunity,
    this.onTap,
    this.onEnroll,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final style = CategoryUtils.getStyleFromList(opportunity.category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21.788),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F8599AD),
            blurRadius: 14.525,
            offset: Offset(0, 1.816),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(21.788)),
            child: SizedBox(
              height: 144,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0x4D000000), Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 11,
                    top: 14,
                    child: _buildTagBadge(style),
                  ),
                  Positioned(
                    right: 11,
                    top: 14,
                    child: _buildSaveButton(),
                  ),
                  if (opportunity.distanceKm != null)
                    Positioned(
                      right: 11,
                      top: 40,
                      child: _buildDistanceBadge(),
                    ),
                  Positioned(
                    left: 11,
                    bottom: 10,
                    child: _buildKidsGroupsBadges(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14.53, 12, 14.53, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posted by ${opportunity.charityName.isNotEmpty ? opportunity.charityName : "Organization"}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF4A583),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  opportunity.title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF262222),
                    height: 18.156 / 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${opportunity.charityName}${_durationText.isNotEmpty ? ", $_durationText" : ""}',
                  style: GoogleFonts.inter(
                    fontSize: 12.709,
                    color: const Color(0xFF262222).withValues(alpha: 0.5),
                    height: 18.156 / 12.709,
                  ),
                ),
                const SizedBox(height: 10),
                if (opportunity.address != null && opportunity.address!.isNotEmpty)
                  _buildInfoRow(
                    IconlyLight.location,
                    opportunity.address!,
                  ),
                if (opportunity.address != null && opportunity.address!.isNotEmpty)
                  const SizedBox(height: 6),
                _buildInfoRow(
                  IconlyLight.calendar,
                  Helpers.formatApiDate(opportunity.startDatetime),
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  IconlyLight.time_circle,
                  Helpers.formatApiTimeRange(
                      opportunity.startDatetime, opportunity.endDatetime),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      IconlyLight.user_1,
                      size: 10.894,
                      color: const Color(0xFF262222).withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      opportunity.isUncapped
                          ? '${opportunity.volunteerCount} volunteers'
                          : '${opportunity.volunteerCount}/${opportunity.volunteersNeeded} volunteers',
                      style: GoogleFonts.inter(
                        fontSize: 10.894,
                        color: const Color(0xFF262222).withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    if (!opportunity.isUncapped)
                    Text(
                      '${opportunity.spotsLeft} spots left',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF4A583),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9077),
                  child: LinearProgressIndicator(
                    value: opportunity.progress,
                    minHeight: 5.447,
                    backgroundColor: const Color(0xFFEDF0F3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFF4A583),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 36.313,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4A583),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.156),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        fontSize: 12.709,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 36.313,
                  child: OutlinedButton(
                    onPressed: onEnroll,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF4A583), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.156),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Enroll Now',
                      style: GoogleFonts.inter(
                        fontSize: 12.709,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF4A583),
                      ),
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

  Widget _buildImage() {
    if (opportunity.imageUrl != null && opportunity.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: opportunity.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFF4A583),
              ),
            ),
          ),
        ),
        errorWidget: (_, _, _) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(IconlyLight.image, size: 40, color: Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 12.709, color: const Color(0xFFF4A583)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.709,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
              height: 18.156 / 12.709,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagBadge(CategoryStyle style) {
    return Container(
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
          Text(style.emoji, style: const TextStyle(fontSize: 9, height: 1)),
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
    );
  }

  Widget _buildDistanceBadge() {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(9077),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('📍', style: TextStyle(fontSize: 9, height: 1)),
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              Helpers.formatDistance(opportunity.distanceKm),
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: onSave,
      child: Icon(
        opportunity.isSaved ? Icons.favorite : Icons.favorite_border,
        size: 22,
        color: opportunity.isSaved
            ? const Color(0xFFF4A583)
            : Colors.white,
      ),
    );
  }

  Widget _buildKidsGroupsBadges() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (opportunity.kidsOk != null) _buildPillBadge(
          emoji: opportunity.kidsOk! ? '🧒' : '🔞',
          label: opportunity.kidsOk! ? 'Kids welcome' : 'Adults only',
          bgColor: opportunity.kidsOk!
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFFEF3C7),
          textColor: opportunity.kidsOk!
              ? const Color(0xFF15803D)
              : const Color(0xFF92400E),
        ),
        if (opportunity.kidsOk != null && opportunity.acceptsGroups)
          const SizedBox(width: 4),
        if (opportunity.acceptsGroups) _buildPillBadge(
          emoji: '👥',
          label: opportunity.maxGroupSize != null
              ? 'Groups (up to ${opportunity.maxGroupSize})'
              : 'Groups welcome',
          bgColor: const Color(0xFFDBEAFE),
          textColor: const Color(0xFF1D4ED8),
        ),
      ],
    );
  }

  Widget _buildPillBadge({
    required String emoji,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9077),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 9, height: 1)),
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _durationText =>
      Helpers.formatDuration(opportunity.startDatetime, opportunity.endDatetime);
}
