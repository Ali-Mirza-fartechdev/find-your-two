import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/volunteer_provider.dart';
import 'my_opportunities_screen.dart';
import 'volunteer_home_screen.dart';
import 'impact_screen.dart';
import 'notifications_screen.dart';
import 'volunteer_profile_screen.dart';

class VolunteerShell extends StatefulWidget {
  const VolunteerShell({super.key});

  @override
  State<VolunteerShell> createState() => _VolunteerShellState();
}

class _VolunteerShellState extends State<VolunteerShell> {
  int _currentIndex = 2;
  int _previousIndex = 2;

  final _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreLocationIfNeeded();
    });
  }

  void _restoreLocationIfNeeded() {
    final oppProvider = context.read<OpportunityProvider>();
    if (oppProvider.hasLocation) return;

    final user = context.read<AuthProvider>().user;
    if (user != null && user.hasLocation) {
      oppProvider.setUserLocation(
        latitude: user.latitude!,
        longitude: user.longitude!,
        address: user.location ?? '',
      );
    }
  }

  void _onTabSelected(int index) {
    _previousIndex = _currentIndex;
    setState(() => _currentIndex = index);

    if (index == 0 && _previousIndex != 0) {
      context.read<OpportunityProvider>().fetchMyOpportunities();
    }
    if (index == 1 && _previousIndex != 1) {
      context.read<VolunteerProvider>().fetchImpact();
    }
    if (index == 3 && _previousIndex != 3) {
      context.read<NotificationProvider>().fetchNotifications();
    }
    if (index == 4 && _previousIndex != 4) {
      context.read<AuthProvider>().fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final currentNav = _navigatorKeys[_currentIndex].currentState;
        if (currentNav != null && currentNav.canPop()) {
          currentNav.pop();
        } else if (_currentIndex != 2) {
          _onTabSelected(2);
        }
      },
      child: Stack(
        children: [
          _buildOffstageTab(0, const MyOpportunitiesScreen()),
          _buildOffstageTab(1, const ImpactScreen()),
          _buildOffstageTab(2, const VolunteerHomeScreen()),
          _buildOffstageTab(3, const NotificationsScreen()),
          _buildOffstageTab(4, const ProfileScreen()),

          // Peach gradient overlay for all tabs except Home
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
            child: _FloatingNavBar(
              selectedIndex: _currentIndex,
              onItemSelected: _onTabSelected,
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

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        const horizontalPadding = 27.0;
        final usableWidth = barWidth - (horizontalPadding * 2);
        final itemWidth = usableWidth / 5;
        final indicatorLeft =
            horizontalPadding +
            (itemWidth * selectedIndex) +
            (itemWidth / 2) -
            20.5;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // White pill container
            Material(
              color: Colors.transparent,
              child: Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 27),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(
                    0,
                    IconlyLight.calendar,
                    IconlyBold.calendar,
                    'Events',
                  ),
                  _buildNavItem(
                    1,
                    IconlyLight.chart,
                    IconlyBold.chart,
                    'Impact',
                  ),
                  _buildNavItem(2, IconlyLight.home, IconlyBold.home, 'Home'),
                  _buildNavItem(
                    3,
                    IconlyLight.notification,
                    IconlyBold.notification,
                    'Alert',
                  ),
                  _buildNavItem(
                    4,
                    IconlyLight.profile,
                    IconlyBold.profile,
                    'Profile',
                  ),
                ],
              ),
            ),
            ),

            // Coral indicator bar floating above active tab
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

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
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
