import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, IconlyLight.calendar, 'Events'),
          _buildNavItem(1, IconlyLight.chart, 'Impact'),
          _buildHomeItem(),
          _buildNavItem(3, IconlyLight.notification, 'Alert'),
          _buildNavItem(4, IconlyLight.profile, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? const Color(0xFFF4A583) : const Color(0xFF262222),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? const Color(0xFFF4A583)
                  : const Color(0xFF262222),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeItem() {
    final isActive = currentIndex == 2;

    return GestureDetector(
      onTap: () => onTap(2),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active indicator
          if (isActive)
            Container(
              width: 41,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4A583),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          Icon(
            IconlyLight.home,
            size: 28,
            color: isActive ? const Color(0xFFF4A583) : const Color(0xFF262222),
          ),
          const SizedBox(height: 3),
          Text(
            'Home',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFFF4A583)
                  : const Color(0xFF262222),
            ),
          ),
        ],
      ),
    );
  }
}
