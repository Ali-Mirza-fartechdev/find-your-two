import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/group_provider.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/charity/charity_shell.dart';
import 'screens/volunteer/location_setup_screen.dart';
import 'screens/volunteer/volunteer_shell.dart';
import 'services/deep_link_service.dart';

class _NoStretchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // No glow or stretch
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FindYourTwoApp extends StatefulWidget {
  const FindYourTwoApp({super.key});

  @override
  State<FindYourTwoApp> createState() => _FindYourTwoAppState();
}

class _FindYourTwoAppState extends State<FindYourTwoApp> {
  final _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _deepLinkService.onGroupJoinToken = _handleGroupJoinToken;
    _deepLinkService.init();
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  void _handleGroupJoinToken(String token) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    final groupProvider = ctx.read<GroupProvider>();

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return FutureBuilder<bool>(
          future: groupProvider.joinGroup(token: token),
          builder: (_, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFF4A583)),
                    const SizedBox(width: 20),
                    Text(
                      'Joining group...',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            final success = snapshot.data ?? false;
            return AlertDialog(
              title: Text(
                success ? 'Joined!' : 'Could not join',
                style: GoogleFonts.ptSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                ),
              ),
              content: Text(
                success
                    ? 'You have been added to the group.'
                    : groupProvider.errorMessage ?? 'Invalid or expired invite link.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF262222).withValues(alpha: 0.7),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    if (!success) groupProvider.clearError();
                  },
                  child: Text(
                    'OK',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF4A583),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scrollBehavior: _NoStretchScrollBehavior(),
      title: 'FindYourTwo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const SignupScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.locationSetup: (_) => const LocationSetupScreen(),
        AppRoutes.volunteerHome: (_) => const VolunteerShell(),
        AppRoutes.charityHome: (_) => const CharityShell(),
      },
    );
  }
}
