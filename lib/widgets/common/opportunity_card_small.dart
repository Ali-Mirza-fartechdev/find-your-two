import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../models/opportunity.dart';
import '../../utils/category_utils.dart';
import '../../utils/helpers.dart';

class OpportunityCardSmall extends StatelessWidget {
  final Opportunity opportunity;
  final VoidCallback? onTap;

  const OpportunityCardSmall({
    super.key,
    required this.opportunity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = CategoryUtils.getStyleFromList(opportunity.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 203,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C000000),
              blurRadius: 20,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: SizedBox(
                height: 116,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(),
                    Positioned(
                      left: 7,
                      top: 11,
                      child: _buildTagBadge(style),
                    ),
                    if (opportunity.kidsOk != null)
                      Positioned(
                        left: 7,
                        bottom: 8,
                        child: _buildKidsBadge(),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                      height: 15.9 / 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opportunity.charityName,
                    style: GoogleFonts.inter(
                      fontSize: 10.9,
                      color: const Color(0xFF262222).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        IconlyLight.calendar,
                        size: 10,
                        color: Color(0xFFF4A583),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Helpers.formatApiDate(opportunity.startDatetime),
                        style: GoogleFonts.inter(
                          fontSize: 10.9,
                          color:
                              const Color(0xFF262222).withValues(alpha: 0.5),
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
        child: Icon(IconlyLight.image, size: 32, color: Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _buildKidsBadge() {
    final isKidsOk = opportunity.kidsOk!;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isKidsOk ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(9077),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            isKidsOk ? '🧒' : '🔞',
            style: const TextStyle(fontSize: 9, height: 1),
          ),
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              isKidsOk ? 'Kids' : 'Adults',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: isKidsOk
                    ? const Color(0xFF15803D)
                    : const Color(0xFF92400E),
                height: 1,
              ),
            ),
          ),
        ],
      ),
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
}
