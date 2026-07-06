import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1 — Email
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // Step 2 — OTP (6 digits)
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  String? _resetToken;

  // Step 3 — New Password
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  // ─── Step 1: Send OTP ──────────────────────────────────────────────

  Future<void> _handleEmailSubmit() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().forgotPassword(
            email: _emailController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _isLoading = false);
      _goToStep(1);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final error = context.read<AuthProvider>().errorMessage;
      if (error != null && mounted) {
        Helpers.showSnackBar(context, message: error);
      }
    }
  }

  // ─── Step 2: Verify OTP ────────────────────────────────────────────

  Future<void> _handleOtpSubmit() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      Helpers.showSnackBar(context, message: 'Please enter the full 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await context.read<AuthProvider>().verifyOtp(
            email: _emailController.text.trim(),
            otp: otp,
          );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _resetToken = token;
      });
      _goToStep(2);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final error = context.read<AuthProvider>().errorMessage;
      if (error != null && mounted) {
        Helpers.showSnackBar(context, message: error);
      }
    }
  }

  // ─── Step 3: Reset Password ────────────────────────────────────────

  Future<void> _handleResetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    if (_resetToken == null) {
      Helpers.showSnackBar(context, message: 'Reset token missing. Please restart the flow.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().resetPassword(
            email: _emailController.text.trim(),
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
            resetToken: _resetToken!,
          );
      if (!mounted) return;
      setState(() => _isLoading = false);
      _goToStep(3);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final error = context.read<AuthProvider>().errorMessage;
      if (error != null && mounted) {
        Helpers.showSnackBar(context, message: error);
      }
    }
  }

  // ─── Step 4: Back to login ─────────────────────────────────────────

  void _handleGoToLogin() {
    Navigator.of(context)
        .popUntil((route) => route.settings.name == AppRoutes.login);
  }

  // ─── Resend OTP ────────────────────────────────────────────────────

  Future<void> _resendOtp() async {
    try {
      await context.read<AuthProvider>().forgotPassword(
            email: _emailController.text.trim(),
          );
      if (mounted) {
        Helpers.showSnackBar(
          context,
          message: 'A new code has been sent to your email',
          backgroundColor: const Color(0xFF15B789),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1EmailInput(),
          _buildStep2EnterCode(),
          _buildStep3NewPassword(),
          _buildStep4Success(),
        ],
      ),
    );
  }

  // ─── Shared white card layout ──────────────────────────────────────

  Widget _buildCardLayout({required List<Widget> children}) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        Positioned(
          left: 0, right: 0, top: 0, height: size.height * 0.15,
          child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
        ),
        Positioned(
          left: 0, right: 0, top: 0, height: size.height * 0.15,
          child: Container(color: const Color(0xE60D0808)),
        ),
        Positioned(
          left: 0, right: 0, top: size.height * 0.15, bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(33),
                topRight: Radius.circular(33),
              ),
              border: Border(top: BorderSide(color: Color(0xFFF4A583), width: 2)),
            ),
          ),
        ),
        Positioned(
          left: 0, right: 0, top: size.height * 0.15, bottom: 0,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 25, top: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _goBack,
                    child: const Icon(IconlyLight.arrow_left, color: Color(0xFF0D0808), size: 22),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 25,
                    right: 25,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 30,
                  ),
                  child: Column(children: children),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Step 1: Enter email ───────────────────────────────────────────

  Widget _buildStep1EmailInput() {
    return _buildCardLayout(
      children: [
        const SizedBox(height: 45),
        Text(
          "Confirm it's you",
          style: GoogleFonts.ptSerif(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF0D0808), height: 35 / 30),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter your email and we\'ll send you a verification code',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0D0808).withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 30),
        Form(
          key: _emailFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email', style: GoogleFonts.openSans(fontSize: 12, color: const Color(0xFF0D0808).withValues(alpha: 0.6))),
              const SizedBox(height: 8),
              _buildWhiteField('Email Address', _emailController, validator: Validators.email),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildContinueButton(label: 'Continue', onPressed: _handleEmailSubmit),
        const SizedBox(height: 50),
        _buildIllustration('assets/images/work_in_desk.png'),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── Step 2: Enter 6-digit OTP ─────────────────────────────────────

  Widget _buildStep2EnterCode() {
    return _buildCardLayout(
      children: [
        const SizedBox(height: 45),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0D0808).withValues(alpha: 0.6)),
            children: [
              const TextSpan(text: 'Please enter the 6-digit code we sent to\n'),
              TextSpan(
                text: _emailController.text.isNotEmpty ? _emailController.text : 'your email',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0D0808)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 35),

        // 6 OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              width: 44,
              height: 49,
              margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF0D0808)),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF0D0808).withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF0D0808).withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFF4A583)),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),

        const SizedBox(height: 35),
        _buildContinueButton(label: 'Verify Code', onPressed: _handleOtpSubmit),
        const SizedBox(height: 20),

        // Resend
        Center(
          child: GestureDetector(
            onTap: _resendOtp,
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0D0808).withValues(alpha: 0.6)),
                children: [
                  const TextSpan(text: "Didn't get the code? "),
                  TextSpan(
                    text: 'Resend',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: const Color(0xFF0D0808), decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 50),
        _buildIllustration('assets/images/thumbs_up.png'),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── Step 3: Set new password ──────────────────────────────────────

  Widget _buildStep3NewPassword() {
    return _buildCardLayout(
      children: [
        const SizedBox(height: 45),
        Text(
          'Set New Password',
          style: GoogleFonts.ptSerif(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF0D0808), height: 35 / 30),
        ),
        const SizedBox(height: 16),
        Text(
          'Create a strong password for your account',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0D0808).withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 30),
        Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Password', style: GoogleFonts.openSans(fontSize: 12, color: const Color(0xFF0D0808).withValues(alpha: 0.6))),
              const SizedBox(height: 8),
              _buildWhiteField('Enter new password', _newPasswordController, obscure: true, validator: Validators.password),
              const SizedBox(height: 16),
              Text('Confirm Password', style: GoogleFonts.openSans(fontSize: 12, color: const Color(0xFF0D0808).withValues(alpha: 0.6))),
              const SizedBox(height: 8),
              _buildWhiteField('Confirm new password', _confirmPasswordController, obscure: true, validator: (val) {
                if (val == null || val.isEmpty) return 'Please confirm your password';
                if (val != _newPasswordController.text) return 'Passwords do not match';
                return null;
              }),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildContinueButton(label: 'Reset Password', onPressed: _handleResetPassword),
        const SizedBox(height: 50),
        _buildIllustration('assets/images/work_in_beanbag.png'),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── Step 4: Success ───────────────────────────────────────────────

  Widget _buildStep4Success() {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        Positioned(
          left: 0, right: 0, top: 0, height: size.height * 0.15,
          child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
        ),
        Positioned(
          left: 0, right: 0, top: 0, height: size.height * 0.15,
          child: Container(color: const Color(0xE60D0808)),
        ),
        Positioned(
          left: 0, right: 0, top: size.height * 0.15, bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(33), topRight: Radius.circular(33)),
              border: Border(top: BorderSide(color: Color(0xFFF4A583), width: 2)),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0, right: 0, top: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(33), topRight: Radius.circular(33)),
                    child: Opacity(
                      opacity: 0.8,
                      child: Image.asset('assets/images/confetti.png', width: double.infinity, fit: BoxFit.fitWidth),
                    ),
                  ),
                ),
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          children: [
                            SizedBox(height: size.height * 0.1),
                            Text(
                              'Password Reset\nSuccessfully',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.ptSerif(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF0D0808), height: 35 / 30),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your password has been updated. You can now log in with your new password.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0D0808).withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 30),
                            _buildContinueButton(label: 'Back to Login', onPressed: _handleGoToLogin),
                            const SizedBox(height: 50),
                            _buildIllustration('assets/images/thumbs_up.png', height: 280),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared widgets ────────────────────────────────────────────────

  Widget _buildWhiteField(
    String hintText,
    TextEditingController controller, {
    String? Function(String?)? validator,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(-2, 3))],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: obscure ? TextInputType.visiblePassword : TextInputType.emailAddress,
        validator: validator,
        style: GoogleFonts.openSans(fontSize: 14, color: const Color(0xFF0D0808)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.openSans(fontSize: 12, color: const Color(0xFF0D0808).withValues(alpha: 0.3)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide(color: const Color(0xFF0D0808).withValues(alpha: 0.1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide(color: const Color(0xFF0D0808).withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: const BorderSide(color: Color(0xFFF4A583))),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: const BorderSide(color: AppColors.error)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: const BorderSide(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildContinueButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF4A583),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99),
            side: BorderSide(color: const Color(0xFFF4A583).withValues(alpha: 0.2)),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: GoogleFonts.ptSerif(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildIllustration(String asset, {double height = 260}) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset('assets/images/forgot_password_illustration.png', fit: BoxFit.cover, alignment: Alignment.topCenter),
            ),
          ),
          Positioned(
            right: -25, bottom: 0, width: 220, height: 200,
            child: Image.asset(asset, fit: BoxFit.contain, alignment: Alignment.bottomRight),
          ),
        ],
      ),
    );
  }
}
