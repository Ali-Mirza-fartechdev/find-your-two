import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      _navigateAfterAuth(authProvider);
    } else if (authProvider.errorMessage != null) {
      if (mounted) Helpers.showSnackBar(context, message: authProvider.errorMessage!);
      authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            right: -500,
            child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
          ),

          // Dark overlay (90% opacity)
          Positioned.fill(child: Container(color: const Color(0xE60D0808))),

          // Bottom gradient shade
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.46,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x000D0808),
                    Color(0x800D0808),
                    Color(0xFF0D0808),
                  ],
                  stops: [0.04, 0.51, 0.98],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 25,
                right: 25,
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.12),

                    // Title
                    Center(
                      child: Text(
                        'Log In',
                        style: GoogleFonts.ptSerif(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 45 / 30,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Email label
                    Text(
                      'Email',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: const Color(0xFF0D0808),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: GoogleFonts.openSans(
                          fontSize: 12,
                          color: const Color(0xFF0D0808).withValues(alpha: 0.3),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: BorderSide(
                            color: const Color(
                              0xFFF4A583,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: BorderSide(
                            color: const Color(
                              0xFFF4A583,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: const BorderSide(
                            color: Color(0xFFF4A583),
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Password label
                    Text(
                      'Password',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: Validators.password,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: const Color(0xFF0D0808),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: GoogleFonts.openSans(
                          fontSize: 12,
                          color: const Color(0xFF0D0808).withValues(alpha: 0.3),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Icon(
                              _obscurePassword
                                  ? IconlyLight.hide
                                  : IconlyLight.show,
                              size: 18,
                              color: const Color(0xFF0D0808).withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minHeight: 18,
                          minWidth: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: BorderSide(
                            color: const Color(
                              0xFFF4A583,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: BorderSide(
                            color: const Color(
                              0xFFF4A583,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: const BorderSide(
                            color: Color(0xFFF4A583),
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Remember me & Forgot password row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Remember me
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: Row(
                            children: [
                              // Custom small toggle (32x18px)
                              Container(
                                width: 32,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _rememberMe
                                      ? const Color(0xFFF4A583)
                                      : const Color(0xFFA09F99),
                                  borderRadius: BorderRadius.circular(48.363),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: _rememberMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 1.935,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Remember me',
                                style: GoogleFonts.openSans(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Forgot password
                        GestureDetector(
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.forgotPassword);
                          },
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withValues(alpha: 0.8),
                              decorationThickness: 0.5,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: authProvider.state == AuthState.loading
                            ? null
                            : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF4A583),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                            side: BorderSide(
                              color: const Color(
                                0xFFF4A583,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: authProvider.state == AuthState.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Log In',
                                style: GoogleFonts.ptSerif(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // Or login with divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.15),
                            thickness: 0.97,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.476),
                          child: Text(
                            'Or login with',
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.2),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Social login buttons
                    Row(
                      children: [
                        _buildSocialSvgButton(
                          'assets/icons/social_google.svg',
                          17.4,
                          onTap: _handleGoogleLogin,
                        ),
                        if (Platform.isIOS) ...[
                          const SizedBox(width: 10),
                          _buildSocialSvgButton(
                            'assets/icons/social_apple.svg',
                            19,
                            onTap: _handleAppleLogin,
                          ),
                        ],
                        const SizedBox(width: 10),
                        _buildSocialSvgButton(
                          'assets/icons/social_facebook.svg',
                          18.4,
                          onTap: () {
                            Helpers.showSnackBar(context, message: 'Facebook login coming soon');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Sign up link
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.register);
                        },
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Signup',
                                style: GoogleFonts.openSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFFF4A583),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loginWithGoogle();
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      _navigateAfterAuth(authProvider);
    } else if (authProvider.errorMessage != null) {
      final msg = authProvider.errorMessage!;
      if (!_isCancelError(msg)) {
        Helpers.showSnackBar(context, message: _friendlyError(msg));
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loginWithApple();
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      _navigateAfterAuth(authProvider);
    } else if (authProvider.errorMessage != null) {
      final msg = authProvider.errorMessage!;
      if (!_isCancelError(msg)) {
        Helpers.showSnackBar(context, message: _friendlyError(msg));
      }
    }
  }

  void _navigateAfterAuth(AuthProvider authProvider) {
    final user = authProvider.user!;
    String route;
    if (user.isCharity) {
      route = AppRoutes.charityHome;
    } else if (user.hasLocation) {
      context.read<OpportunityProvider>().setUserLocation(
        latitude: user.latitude!,
        longitude: user.longitude!,
        address: user.location ?? '',
      );
      route = AppRoutes.volunteerHome;
    } else {
      route = AppRoutes.locationSetup;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  bool _isCancelError(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('cancelled') ||
        lower.contains('canceled') ||
        lower.contains('user_cancelled') ||
        lower.contains('AuthorizationErrorCode.canceled');
  }

  String _friendlyError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Please check your internet connection and try again';
    }
    if (lower.contains('url scheme') || lower.contains('platformexception')) {
      return 'Sign in is temporarily unavailable. Please try again later.';
    }
    if (lower.contains('credential') || lower.contains('token')) {
      return 'Authentication failed. Please try again.';
    }
    // If it's a clean API message, show it; otherwise generic
    if (msg.length < 100 && !msg.contains('Exception')) {
      return msg;
    }
    return 'Something went wrong. Please try again.';
  }

  Widget _buildSocialSvgButton(String svgPath, double iconHeight, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 53.199,
          decoration: BoxDecoration(
            color: const Color(0xFF484848),
            borderRadius: BorderRadius.circular(5.804),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 9.689,
                offset: Offset(0, 12.112),
              ),
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 5.146,
                offset: Offset(0, 6.432),
              ),
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 2.141,
                offset: Offset(0, 2.677),
              ),
            ],
          ),
          child: Center(child: SvgPicture.asset(svgPath, height: iconHeight)),
        ),
      ),
    );
  }
}
