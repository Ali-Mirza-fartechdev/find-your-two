import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/charity_provider.dart';
import '../../utils/helpers.dart';
import 'charity_settings_screen.dart';
import 'claim_listing_screen.dart';
import '../volunteer/volunteer_shell.dart';

class CharityProfileScreen extends StatefulWidget {
  final bool isCreateMode;
  final VoidCallback? onProfileCreated;
  final VoidCallback? onBackToVolunteer;

  const CharityProfileScreen({
    super.key,
    this.isCreateMode = false,
    this.onProfileCreated,
    this.onBackToVolunteer,
  });

  @override
  State<CharityProfileScreen> createState() => _CharityProfileScreenState();
}

class _CharityProfileScreenState extends State<CharityProfileScreen> {
  File? _profileImage;
  final _imagePicker = ImagePicker();
  bool _isSaving = false;
  bool _isUploading = false;

  final _orgNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _missionCtrl = TextEditingController();
  final _socialWebCtrl = TextEditingController();
  final _socialTwitterCtrl = TextEditingController();
  final _socialInstaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isCreateMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
    }
  }

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _missionCtrl.dispose();
    _socialWebCtrl.dispose();
    _socialTwitterCtrl.dispose();
    _socialInstaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final provider = context.read<CharityProvider>();
    await provider.fetchProfile();
    if (mounted) _populateFields();
  }

  void _populateFields() {
    final profile = context.read<CharityProvider>().profile;
    if (profile == null) return;
    _orgNameCtrl.text = profile.orgName;
    _emailCtrl.text = profile.email ?? '';
    _phoneCtrl.text = profile.phone ?? '';
    _websiteCtrl.text = profile.website ?? '';
    _missionCtrl.text = profile.mission ?? '';
    _socialWebCtrl.text = profile.socialLinks['website'] ?? '';
    _socialTwitterCtrl.text = profile.socialLinks['twitter'] ?? '';
    _socialInstaCtrl.text = profile.socialLinks['instagram'] ?? '';
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final previousImage = _profileImage;
    setState(() {
      _profileImage = File(picked.path);
      _isUploading = true;
    });

    final provider = context.read<CharityProvider>();
    final url = await provider.uploadLogo(picked.path);

    if (!mounted) return;

    if (url == null) {
      setState(() {
        _profileImage = previousImage;
        _isUploading = false;
      });
      Helpers.showSnackBar(
        context,
        message: provider.errorMessage ?? 'Failed to upload logo',
        backgroundColor: Colors.red,
      );
    } else {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    final provider = context.read<CharityProvider>();

    final socialLinks = <String, String>{};
    if (_socialWebCtrl.text.trim().isNotEmpty) {
      socialLinks['website'] = _socialWebCtrl.text.trim();
    }
    if (_socialTwitterCtrl.text.trim().isNotEmpty) {
      socialLinks['twitter'] = _socialTwitterCtrl.text.trim();
    }
    if (_socialInstaCtrl.text.trim().isNotEmpty) {
      socialLinks['instagram'] = _socialInstaCtrl.text.trim();
    }

    setState(() => _isSaving = true);

    if (widget.isCreateMode) {
      final orgName = _orgNameCtrl.text.trim();
      if (orgName.isEmpty) {
        setState(() => _isSaving = false);
        Helpers.showSnackBar(
          context,
          message: 'Organization name is required',
          backgroundColor: Colors.red,
        );
        return;
      }

      final success = await provider.createProfile(
        orgName: orgName,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        website:
            _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        mission:
            _missionCtrl.text.trim().isEmpty ? null : _missionCtrl.text.trim(),
        socialLinks: socialLinks.isEmpty ? null : socialLinks,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        _showCreateSuccessConfirmation();
      } else {
        Helpers.showSnackBar(
          context,
          message: provider.errorMessage ?? 'Failed to create profile',
          backgroundColor: Colors.red,
        );
      }
    } else {
      final success = await provider.updateProfile(
        orgName: _orgNameCtrl.text.trim().isEmpty
            ? null
            : _orgNameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        website:
            _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        mission:
            _missionCtrl.text.trim().isEmpty ? null : _missionCtrl.text.trim(),
        socialLinks: socialLinks.isEmpty ? null : socialLinks,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        Helpers.showSnackBar(
          context,
          message: 'Organization profile updated successfully',
          backgroundColor: const Color(0xFF15B789),
        );
      } else {
        Helpers.showSnackBar(
          context,
          message: provider.errorMessage ?? 'Failed to update profile',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CharityProvider>(
      builder: (context, provider, _) {
        // Show loading state in edit mode when profile hasn't loaded yet
        if (!widget.isCreateMode &&
            provider.profile == null &&
            provider.isLoading) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: const Color(0xFFF4A583),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Positioned(
                left: -295,
                top: -261,
                width: 894,
                height: 1763,
                child: SvgPicture.asset('assets/images/home_bg_blob.svg',
                    fit: BoxFit.fill),
              ),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                      child: _buildDarkHeader(context, provider)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                      child: Column(
                        children: [
                          if (widget.isCreateMode) ...[
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ClaimListingScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4A583)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14.64),
                                  border: Border.all(
                                    color: const Color(0xFFF4A583)
                                        .withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      IconlyLight.search,
                                      size: 16,
                                      color: const Color(0xFFF4A583),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Already have a listing? Claim it',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFF4A583),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          _buildFieldCard('Organization Name', _orgNameCtrl),
                          const SizedBox(height: 14.5),
                          _buildFieldCard('Email', _emailCtrl),
                          const SizedBox(height: 14.5),
                          _buildFieldCard('Phone', _phoneCtrl),
                          const SizedBox(height: 14.5),
                          _buildFieldCard('Website', _websiteCtrl),
                          const SizedBox(height: 14.5),
                          _buildFieldCard('Mission', _missionCtrl,
                              maxLines: 3),
                          const SizedBox(height: 14.5),
                          _buildSocialLinksCard(),
                          const SizedBox(height: 20),
                          _buildSaveButton(),
                          const SizedBox(height: 20),
                          if (widget.isCreateMode)
                            _buildBackToVolunteerButton()
                          else
                            _buildSwitchButton(),
                          const SizedBox(height: 150),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Dark Header --------------------------------------------------------

  Widget _buildDarkHeader(BuildContext context, CharityProvider provider) {
    final profile = provider.profile;
    final logoUrl = profile?.logoUrl;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -0.5),
          end: Alignment(1, 1),
          colors: [Color(0xFF262222), Color(0xFF0D0808)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    _buildGlassCircle(
                      icon: IconlyLight.arrow_left,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                  const Spacer(),
                  // Profile badge
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(58),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 0.685,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IconlyLight.category,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          widget.isCreateMode
                              ? 'New Profile'
                              : 'Charity Profile',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isCreateMode) ...[
                    const SizedBox(width: 8),
                    _buildGlassCircle(
                      icon: IconlyLight.setting,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CharitySettingsScreen()),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 25),
            // Avatar
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 67,
                    height: 67,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 21,
                          offset: const Offset(0, 17),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _isUploading
                          ? Container(
                              color: const Color(0xFF262222),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFFF4A583),
                                  ),
                                ),
                              ),
                            )
                          : _profileImage != null
                              ? Image.file(_profileImage!, fit: BoxFit.cover,
                                  width: 67, height: 67)
                              : logoUrl != null && logoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: logoUrl,
                                      width: 67,
                                      height: 67,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: const Color(0xFF1A1414),
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
                                      errorWidget: (_, __, ___) =>
                                          _buildFallbackAvatar(),
                                    )
                                  : _buildFallbackAvatar(),
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF262222), width: 1.6),
                      ),
                      child: const Icon(IconlyLight.edit,
                          size: 10, color: Color(0xFF262222)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Name
            Text(
              _orgNameCtrl.text.isEmpty
                  ? (widget.isCreateMode ? 'Your Organization' : '')
                  : _orgNameCtrl.text,
              style: GoogleFonts.inter(
                fontSize: 17.258,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 23.233 / 17.258,
              ),
            ),
            if (!widget.isCreateMode &&
                profile != null &&
                profile.verified) ...[
              const SizedBox(height: 5),
              Text(
                '\u2713  Verified Organization',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF4A583),
                  height: 13.276 / 10,
                ),
              ),
            ],
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 67,
      height: 67,
      color: const Color(0xFF1A1414),
      child: const Center(
        child: Icon(IconlyLight.category, size: 28, color: Color(0xFFF4A583)),
      ),
    );
  }

  Widget _buildGlassCircle(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 0.685,
          ),
        ),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    );
  }

  // --- Field Card ----------------------------------------------------------

  Widget _buildFieldCard(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.64),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6.373,
              offset: Offset(0, 2.752)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14.5, 10, 14.5, 0),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.614,
                color: const Color(0xFF262222).withValues(alpha: 0.5),
                height: 14.152 / 10.614,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14.5, 0, 14.5, 10),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(
                fontSize: 12.383,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
                height: 17.69 / 12.383,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Social Links Card ---------------------------------------------------

  Widget _buildSocialLinksCard() {
    return Container(
      padding: const EdgeInsets.all(14.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.64),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6.373,
              offset: Offset(0, 2.752)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Social Links',
            style: GoogleFonts.inter(
              fontSize: 13.664,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
              height: 17.582 / 13.664,
            ),
          ),
          const SizedBox(height: 10),
          _buildSocialSvgRow('assets/icons/social_website.svg', _socialWebCtrl),
          Divider(
              color: const Color(0xFF262222).withValues(alpha: 0.1), height: 1),
          _buildSocialSvgRow(
              'assets/icons/social_twitter.svg', _socialTwitterCtrl),
          Divider(
              color: const Color(0xFF262222).withValues(alpha: 0.1), height: 1),
          _buildSocialSvgRow(
              'assets/icons/social_instagram.svg', _socialInstaCtrl),
        ],
      ),
    );
  }

  Widget _buildSocialSvgRow(String svgPath, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SvgPicture.asset(svgPath, width: 14.5, height: 14.5),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(
                fontSize: 12.688,
                color: const Color(0xFF262222),
                height: 18.125 / 12.688,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Save Button ---------------------------------------------------------

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: Container(
        width: double.infinity,
        height: 51,
        decoration: BoxDecoration(
          color: const Color(0xFF15B789),
          borderRadius: BorderRadius.circular(99),
        ),
        alignment: Alignment.center,
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                widget.isCreateMode ? 'Create Profile' : 'Save Changes',
                style: GoogleFonts.inter(
                  fontSize: 13.254,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // --- Back to Volunteer (create mode) -------------------------------------

  Widget _buildBackToVolunteerButton() {
    return GestureDetector(
      onTap: () async {
        if (widget.onBackToVolunteer != null) {
          widget.onBackToVolunteer!();
        } else {
          await context.read<AuthProvider>().switchMode(mode: 'volunteer');
          if (!context.mounted) return;
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(builder: (_) => const VolunteerShell()),
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: 51,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: const Color(0xFF262222).withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Back to Volunteer Mode',
          style: GoogleFonts.inter(
            fontSize: 13.254,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF262222),
          ),
        ),
      ),
    );
  }

  // --- Switch to Volunteer Profile (edit mode) -----------------------------

  Widget _buildSwitchButton() {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthProvider>().switchMode(mode: 'volunteer');
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (_) => const VolunteerShell()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 67,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1C000000),
                blurRadius: 18.944,
                offset: Offset(0, 2.735)),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14.5),
            Container(
              width: 36.25,
              height: 36.25,
              decoration: BoxDecoration(
                color: const Color(0xFF262222).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/volunteer_mode.svg',
                  width: 18,
                  height: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Switch To Volunteer Profile',
                    style: GoogleFonts.inter(
                      fontSize: 13.58,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                  ),
                  Text(
                    'Manage your organisation & events',
                    style: GoogleFonts.inter(
                      fontSize: 9.76,
                      color: const Color(0xFF65758B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14.5),
          ],
        ),
      ),
    );
  }

  // --- Create Success Confirmation -----------------------------------------

  void _showCreateSuccessConfirmation() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: const Color(0x66000000),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, animation, _) {
          return FadeTransition(
            opacity: animation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(25, 30, 25, 25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 30,
                            offset: Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF15B789).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(IconlyBold.tick_square,
                              size: 36, color: Color(0xFF15B789)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Profile Created!',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF262222),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your charity profile has been created successfully. You can now manage opportunities and volunteers.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF262222)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              if (widget.onProfileCreated != null) {
                                widget.onProfileCreated!();
                              } else {
                                Navigator.of(context).pop(true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF15B789),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Go to Dashboard',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
