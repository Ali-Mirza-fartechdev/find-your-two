import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/charity_provider.dart';
import '../volunteer/volunteer_shell.dart';
import 'charity_dashboard_screen.dart';
import 'charity_profile_screen.dart';
import 'charity_settings_screen.dart';
import 'create_opportunity_screen.dart';
import 'volunteer_attendance_screen.dart';

class CharityShell extends StatefulWidget {
  const CharityShell({super.key});

  @override
  State<CharityShell> createState() => _CharityShellState();
}

class _CharityShellState extends State<CharityShell> {
  int _currentIndex = 2; // Dashboard is default
  bool _profileChecked = false;
  bool _hasProfile = false;

  final _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCharityProfile();
    });
  }

  Future<void> _checkCharityProfile() async {
    final provider = context.read<CharityProvider>();
    await provider.fetchProfile();
    if (mounted) {
      setState(() {
        _profileChecked = true;
        _hasProfile = provider.profile != null;
      });
    }
  }

  Future<void> _switchBackToVolunteer() async {
    await context.read<AuthProvider>().switchMode(mode: 'volunteer');
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (_) => const VolunteerShell()),
      );
    }
  }

  void _onProfileCreated() {
    setState(() {
      _hasProfile = true;
    });
    // Refresh dashboard now that profile exists
    context.read<CharityProvider>().fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    // Still checking profile existence
    if (!_profileChecked) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF4A583)),
        ),
      );
    }

    // No charity profile — show only the create profile screen
    if (!_hasProfile) {
      return CharityProfileScreen(
        isCreateMode: true,
        onProfileCreated: _onProfileCreated,
        onBackToVolunteer: _switchBackToVolunteer,
      );
    }

    // Has profile — show full shell
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final currentNav = _navigatorKeys[_currentIndex].currentState;
        if (currentNav != null && currentNav.canPop()) {
          currentNav.pop();
        } else if (_currentIndex != 2) {
          setState(() => _currentIndex = 2);
        }
      },
      child: Stack(
        children: [
          // Tab screens
          _buildOffstageTab(0, CreateOpportunityScreen(onSaved: () {
            setState(() => _currentIndex = 2); // Switch to Dashboard tab
          })),
          _buildOffstageTab(1, const VolunteerAttendanceScreen()),
          _buildOffstageTab(2, const CharityDashboardScreen()),
          _buildOffstageTab(3, const CharitySettingsScreen()),
          _buildOffstageTab(4, const CharityProfileScreen()),

          // Peach gradient overlay for all tabs except Dashboard
          if (_currentIndex != 2)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 160,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00F4A583),
                        Color(0x18F4A583),
                        Color(0x35F4A583),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // Floating bottom nav bar
          Positioned(
            left: 10,
            right: 10,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: Material(
              color: Colors.transparent,
              child: _CharityNavBar(
                selectedIndex: _currentIndex,
                onItemSelected: (index) {
                  setState(() => _currentIndex = index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffstageTab(int index, Widget screen) {
    return Offstage(
      offstage: _currentIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (_) {
          return MaterialPageRoute(builder: (_) => screen);
        },
      ),
    );
  }

}

// ─── Charity Floating Nav Bar ────────────────────────────────────────

class _CharityNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const _CharityNavBar({
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        const horizontalPadding = 20.0;
        final usableWidth = barWidth - (horizontalPadding * 2);
        final itemWidth = usableWidth / 5;
        final indicatorLeft =
            horizontalPadding + (itemWidth * selectedIndex) + (itemWidth / 2) - 20.5;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 71,
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(0, IconlyLight.plus, IconlyBold.plus, 'Create'),
                  _buildNavItem(1, IconlyLight.user_1, IconlyBold.user_3, 'Volunteer'),
                  _buildNavItem(2, IconlyLight.category, IconlyBold.category, 'Dashboard'),
                  _buildNavItem(3, IconlyLight.setting, IconlyBold.setting, 'Setting'),
                  _buildNavItem(4, IconlyLight.profile, IconlyBold.profile, 'Profile'),
                ],
              ),
            ),
            // Coral indicator bar
            Positioned(
              top: -5,
              left: indicatorLeft,
              child: Container(
                width: 41,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A583),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: isActive ? 50 : 35,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: isActive ? 28 : 20,
              color: isActive
                  ? const Color(0xFFF4A583)
                  : const Color(0xFF262222),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isActive ? 12 : 8,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFFF4A583)
                    : const Color(0xFF262222),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
