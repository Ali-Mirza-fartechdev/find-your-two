import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.register(
      name: _userNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      role: 'volunteer',
    );

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.locationSetup);
    } else if (authProvider.errorMessage != null) {
      if (mounted) Helpers.showSnackBar(context, message: authProvider.errorMessage!);
      authProvider.clearError();
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.openSans(
        fontSize: 12,
        color: const Color(0xFF0D0808).withValues(alpha: 0.3),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minHeight: 18, minWidth: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(99),
        borderSide: BorderSide(
          color: const Color(0xFFF4A583).withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(99),
        borderSide: BorderSide(
          color: const Color(0xFFF4A583).withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(99),
        borderSide: const BorderSide(color: Color(0xFFF4A583)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(99),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(99),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  TextStyle get _inputTextStyle =>
      GoogleFonts.openSans(fontSize: 14, color: const Color(0xFF0D0808));

  TextStyle get _labelStyle => GoogleFonts.openSans(
    fontSize: 12,
    color: Colors.white.withValues(alpha: 0.8),
  );

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

          // Dark overlay (90%)
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
                    SizedBox(height: size.height * 0.06),

                    // Title
                    Center(
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.ptSerif(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 45 / 30,
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // User Name
                    Text('User Name', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _userNameController,
                      validator: (v) => Validators.required(v, 'User name'),
                      style: _inputTextStyle,
                      decoration: _inputDecoration(hintText: 'User Name'),
                    ),

                    const SizedBox(height: 15),

                    // Email
                    Text('Email', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      style: _inputTextStyle,
                      decoration: _inputDecoration(hintText: 'Email Address'),
                    ),

                    const SizedBox(height: 15),

                    // Password
                    Text('Password', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: Validators.password,
                      style: _inputTextStyle,
                      decoration: _inputDecoration(
                        hintText: 'Password',
                        suffixIcon: GestureDetector(
                          onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Icon(
                              _obscurePassword
                                  ? IconlyLight.hide
                                  : IconlyLight.show,
                              size: 18,
                              color: const Color(
                                0xFF0D0808,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Confirm Password
                    Text('Confirm Password', style: _labelStyle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      validator: (v) => Validators.confirmPassword(
                        v,
                        _passwordController.text,
                      ),
                      style: _inputTextStyle,
                      decoration: _inputDecoration(
                        hintText: 'Confirm password',
                        suffixIcon: GestureDetector(
                          onTap: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Icon(
                              _obscureConfirmPassword
                                  ? IconlyLight.hide
                                  : IconlyLight.show,
                              size: 18,
                              color: const Color(
                                0xFF0D0808,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // Sign Up button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: authProvider.state == AuthState.loading
                            ? null
                            : _handleSignUp,
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
                                'Sign Up',
                                style: GoogleFonts.ptSerif(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // Or signup with divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.15),
                            thickness: 0.97,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15.476,
                          ),
                          child: Text(
                            'Or signup with',
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.15),
                            thickness: 0.97,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14.509),

                    // Social signup buttons
                    Row(
                      children: [
                        _buildSocialSvgButton(
                          'assets/icons/social_google.svg',
                          17.4,
                          onTap: _handleGoogleSignup,
                        ),
                        if (Platform.isIOS) ...[
                          const SizedBox(width: 9.673),
                          _buildSocialSvgButton(
                            'assets/icons/social_apple.svg',
                            19,
                            onTap: _handleAppleSignup,
                          ),
                        ],
                        const SizedBox(width: 9.673),
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

                    // Login link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Login',
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

  Future<void> _handleGoogleSignup() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loginWithGoogle();
    if (!mounted) return;
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.locationSetup);
    } else if (authProvider.errorMessage != null) {
      final msg = authProvider.errorMessage!;
      if (!_isCancelError(msg)) {
        Helpers.showSnackBar(context, message: _friendlyError(msg));
      }
    }
  }

  Future<void> _handleAppleSignup() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loginWithApple();
    if (!mounted) return;
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.locationSetup);
    } else if (authProvider.errorMessage != null) {
      final msg = authProvider.errorMessage!;
      if (!_isCancelError(msg)) {
        Helpers.showSnackBar(context, message: _friendlyError(msg));
      }
    }
  }

  bool _isCancelError(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('cancelled') || lower.contains('canceled') || lower.contains('user_cancelled');
  }

  String _friendlyError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('network') || lower.contains('connection')) return 'Please check your internet connection and try again';
    if (lower.contains('url scheme') || lower.contains('platformexception')) return 'Sign in is temporarily unavailable. Please try again later.';
    if (lower.contains('credential') || lower.contains('token')) return 'Authentication failed. Please try again.';
    if (msg.length < 100 && !msg.contains('Exception')) return msg;
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
