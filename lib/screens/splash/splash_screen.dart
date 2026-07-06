import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete =
        prefs.getBool(AppConstants.onboardingKey) ?? false;

    if (!mounted) return;

    if (!onboardingComplete) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      final user = authProvider.user!;
      if (user.isCharity) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.charityHome);
      } else if (user.hasLocation) {
        // User has saved location — restore it and skip location setup
        context.read<OpportunityProvider>().setUserLocation(
          latitude: user.latitude!,
          longitude: user.longitude!,
          address: user.location ?? '',
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.volunteerHome);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.locationSetup);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top-left radial glow shape (Figma: left:-295, top:-261, 522x522)
          Positioned(
            left: -295,
            top: -261,
            width: 522,
            height: 522,
            child: SvgPicture.asset(
              'assets/images/shape_hands.svg',
              fit: BoxFit.fill,
            ),
          ),

          // Bottom-right radial glow shape (Figma: left:77, top:525, 522x522)
          Positioned(
            left: 77,
            top: 525,
            width: 522,
            height: 522,
            child: SvgPicture.asset(
              'assets/images/shape_hands.svg',
              fit: BoxFit.fill,
            ),
          ),

          // Top hands vector (Figma: 291x315, top:0, takes ~38.8% of height)
          Positioned(
            left: (size.width - 291) / 2,
            top: 0,
            width: 291,
            height: size.height * 0.388,
            child: SvgPicture.asset(
              'assets/images/splash_hands.svg',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),
          ),

          // Bottom hands vector (mirrored, from ~61.3% to bottom)
          Positioned(
            left: (size.width - 291) / 2,
            bottom: 0,
            width: 291,
            height: size.height * 0.388,
            child: Transform.flip(
              flipY: true,
              child: SvgPicture.asset(
                'assets/images/splash_hands.svg',
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // Centered logo with animation (Figma: 268x122px)
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/logo-2.png',
                width: 268,
                height: 122,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
