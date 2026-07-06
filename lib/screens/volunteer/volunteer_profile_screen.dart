import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../utils/helpers.dart';
import '../charity/charity_shell.dart';
import 'groups/my_groups_screen.dart';
import 'saved_opportunities_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final _imagePicker = ImagePicker();

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  final _selectedSkills = <String>{};
  final _selectedInterests = <String>{};
  final _selectedAvailability = <String>{};

  bool _kidsOkPreferred = false;

  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() {
      _fullNameCtrl.text = user.name;
      _emailCtrl.text = user.email;
      _locationCtrl.text = user.location ?? '';

      _selectedSkills
        ..clear()
        ..addAll(user.skills);
      _selectedInterests
        ..clear()
        ..addAll(user.interests);
      _selectedAvailability
        ..clear()
        ..addAll(user.availability);

      _kidsOkPreferred = user.kidsOkPreferred ?? false;

      _initialized = true;
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final authProvider = context.read<AuthProvider>();

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _profileImage = File(picked.path);
      _isUploadingAvatar = true;
    });

    final success = await authProvider.uploadAvatar(picked.path);

    if (mounted) {
      setState(() => _isUploadingAvatar = false);
      if (success) {
        Helpers.showSnackBar(
          context,
          message: 'Profile photo updated',
          backgroundColor: const Color(0xFF15B789),
        );
      } else {
        Helpers.showSnackBar(
          context,
          message: authProvider.errorMessage ?? 'Failed to upload photo',
        );
        setState(() => _profileImage = null);
        authProvider.clearError();
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      name: _fullNameCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      skills: _selectedSkills.toList(),
      interests: _selectedInterests.toList(),
      availability: _selectedAvailability.toList(),
      kidsOkPreferred: _kidsOkPreferred,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Helpers.showSnackBar(
          context,
          message: 'Profile updated successfully',
          backgroundColor: const Color(0xFF15B789),
        );
      } else {
        Helpers.showSnackBar(
          context,
          message: authProvider.errorMessage ?? 'Failed to save changes',
        );
        authProvider.clearError();
      }
    }
  }

  Future<void> _switchToCharity() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.switchMode(mode: 'charity');
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (_) => const CharityShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: -295,
            top: 120,
            width: 894,
            height: 1843,
            child: SvgPicture.asset(
              'assets/images/home_bg_blob.svg',
              fit: BoxFit.fill,
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                  child: _buildVolunteerContent(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(25, 25, 25, 150),
                  child: Column(
                    children: [
                      _buildSaveButton(),
                      const SizedBox(height: 15),
                      _buildSwitchCharityButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Dark Header ───────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Consumer2<AuthProvider, VolunteerProvider>(
      builder: (context, authProvider, volunteerProvider, _) {
        final user = authProvider.user;
        final displayName = _initialized
            ? _fullNameCtrl.text
            : (user?.name ?? 'User');

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
                        _buildGlassButton(
                          icon: IconlyLight.arrow_left,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                      const Spacer(),
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
                            Icon(
                              IconlyBold.heart,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Volunteer Mode',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildGlassButton(
                        icon: Icons.group_outlined,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyGroupsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildGlassButton(
                        icon: IconlyLight.bookmark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SavedOpportunitiesScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildGlassButton(
                        icon: IconlyLight.setting,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Avatar
                GestureDetector(
                  onTap: _isUploadingAvatar ? null : _pickImage,
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
                          child: _isUploadingAvatar
                              ? Container(
                                  color: const Color(0xFF3A3434),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : _profileImage != null
                                  ? Image.file(_profileImage!,
                                      fit: BoxFit.cover,
                                      width: 67,
                                      height: 67)
                                  : (user?.avatarUrl != null &&
                                          user!.avatarUrl!.isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: user.avatarUrl!,
                                          fit: BoxFit.cover,
                                          width: 67,
                                          height: 67,
                                          placeholder: (_, _) =>
                                              _buildAvatarPlaceholder(),
                                          errorWidget: (_, _, _) =>
                                              _buildAvatarPlaceholder(),
                                        )
                                      : _buildAvatarPlaceholder(),
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
                              color: const Color(0xFF262222),
                              width: 1.6,
                            ),
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
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 17.3,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                // Community title badge
                if (user?.communityTitle != null && user!.communityTitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconlyBold.shield_done,
                          size: 12, color: Color(0xFFF4A583)),
                      const SizedBox(width: 4),
                      Text(
                        user.communityTitle!,
                        style: GoogleFonts.inter(
                          fontSize: 6.9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF4A583),
                        ),
                      ),
                    ],
                  ),
                ],

                // Member since
                if (user?.memberSince != null && user!.memberSince!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconlyLight.calendar,
                        size: 8.3,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Member since ${user.memberSince}',
                        style: GoogleFonts.inter(
                          fontSize: 6.9,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 18),

                // Stats bar — uses real impact data
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  height: 51,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 0.66,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildStatItem(
                        '${volunteerProvider.eventsDone}',
                        'Events',
                      ),
                      _buildStatItem(
                        volunteerProvider.totalHours % 1 == 0
                            ? '${volunteerProvider.totalHours.toInt()}'
                            : volunteerProvider.totalHours
                                .toStringAsFixed(1),
                        'Hours',
                      ),
                      _buildStatItem(
                        _formatImpactScore(volunteerProvider.impactScore),
                        'Impact',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatImpactScore(Map<String, dynamic> score) {
    final total = (score['total'] as num?)?.toInt() ?? 0;
    return '$total';
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
            width: 0.7,
          ),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Volunteer Content ─────────────────────────────────────────────
  Widget _buildVolunteerContent() {
    return Column(
      children: [
        _buildPersonalInfoCard(
          title: 'Personal Information',
          fields: [
            _EditableField('Full Name', _fullNameCtrl, (_) {}),
            _EditableField('Email', _emailCtrl, (_) {}, readOnly: true),
            _EditableField('Location', _locationCtrl, (_) {}, isLast: true),
          ],
        ),
        const SizedBox(height: 20),
        _buildChipSection('Skills & Expertise', [
          ['Teaching', 'Event Support'],
          ['Environmental Work', 'Food Distribution'],
          ['Medical Aid', 'Construction', 'Coding'],
          ['Fundraising', 'Admin', 'Childcare'],
        ], _selectedSkills),
        const SizedBox(height: 20),
        _buildChipSection('Volunteer Interests', [
          ['Environment', 'Education', 'Animals'],
          ['Community', 'Healthcare', 'Arts'],
        ], _selectedInterests),
        const SizedBox(height: 20),
        _buildChipSection('Availability', [
          ['Weekday Mornings', 'Weekday Evenings'],
          ['Saturday', 'Sunday', 'School Holidays'],
        ], _selectedAvailability),
        const SizedBox(height: 20),
        _buildPreferencesSection(),
        const SizedBox(height: 20),
        _buildHomeLocationSection(),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C000000),
            blurRadius: 19,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kid-friendly opportunities',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF262222),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Auto-filter for kid-friendly events when browsing',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF262222).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: _kidsOkPreferred,
                onChanged: (val) => setState(() => _kidsOkPreferred = val),
                activeColor: const Color(0xFFF4A583),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeLocationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C000000),
            blurRadius: 19,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Home Location',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Used to find opportunities near you',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: const Color(0xFF0D0808).withValues(alpha: 0.1),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(-2, 3),
                ),
              ],
            ),
            child: Center(
              child: TextField(
                controller: _locationCtrl,
                cursorColor: const Color(0xFFF4A583),
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D0808),
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your address',
                  hintStyle: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF0D0808).withValues(alpha: 0.3),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 8),
                    child: Icon(IconlyLight.location, size: 18, color: Color(0xFFF4A583)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _detectCurrentLocation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(IconlyLight.discovery, size: 14, color: Color(0xFFF4A583)),
                const SizedBox(width: 6),
                Text(
                  'Use current location',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF4A583),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _detectCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission perm = permission;
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          Helpers.showSnackBar(context, message: 'Location permission denied');
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      String address = '';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = [p.locality, p.administrativeArea, p.country]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
      }

      setState(() {
        _locationCtrl.text = address;
      });

      // Save coordinates to provider so nearby search works immediately
      final oppProvider = context.read<OpportunityProvider>();
      oppProvider.setUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );

      Helpers.showSnackBar(
        context,
        message: 'Location detected',
        backgroundColor: const Color(0xFF15B789),
      );
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, message: 'Could not detect location');
      }
    }
  }

  // ─── Personal Info Card with Editable Fields ──────────────────────
  Widget _buildPersonalInfoCard({
    required String title,
    required List<_EditableField> fields,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C000000),
            blurRadius: 19,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.5, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF262222).withValues(alpha: 0.1),
                  width: 0.9,
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                ),
              ),
            ),
          ),
          ...fields.map((f) => _buildEditableInfoRow(f)),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(_EditableField field) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.5, vertical: 8),
      decoration: field.isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF262222).withValues(alpha: 0.1),
                  width: 0.9,
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: GoogleFonts.inter(
              fontSize: 10.9,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
            ),
          ),
          TextField(
            controller: field.controller,
            onChanged: field.onChanged,
            readOnly: field.readOnly,
            cursorColor: const Color(0xFFF4A583),
            style: GoogleFonts.inter(
              fontSize: 12.7,
              fontWeight: FontWeight.bold,
              color: field.readOnly
                  ? const Color(0xFF262222).withValues(alpha: 0.4)
                  : const Color(0xFF262222),
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
        ],
      ),
    );
  }

  // ─── Chip Section (Skills, Interests, Availability) ────────────────
  Widget _buildChipSection(
    String title,
    List<List<String>> rows,
    Set<String> selected,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C000000),
            blurRadius: 19,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: row.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isSelected = selected.contains(item);
                  return Padding(
                    padding: EdgeInsets.only(left: entry.key > 0 ? 7 : 0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selected.remove(item);
                          } else {
                            selected.add(item);
                          }
                        });
                      },
                      child: Container(
                        height: 25.4,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF262222)
                              : const Color(0xFF262222)
                                  .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(9062),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 10.9,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF262222)
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Save Changes Button ───────────────────────────────────────────
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: Container(
        width: double.infinity,
        height: 52,
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
                'Save Changes',
                style: GoogleFonts.inter(
                  fontSize: 13.6,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ─── Switch Dashboard Button ────────────────────────────────────────
  Widget _buildSwitchCharityButton() {
    return GestureDetector(
      onTap: _switchToCharity,
      child: Container(
        width: double.infinity,
        height: 69,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C000000),
              blurRadius: 19,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 15),
            Container(
              width: 37,
              height: 37,
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
                    'Switch To Charity Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 13.9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                  ),
                  Text(
                    'Manage your organisation & events',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF65758B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 67,
      height: 67,
      color: const Color(0xFF3A3434),
      child: const Center(
        child: Icon(
          IconlyLight.profile,
          size: 32,
          color: Color(0x99FFFFFF),
        ),
      ),
    );
  }
}

class _EditableField {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isLast;
  final bool readOnly;

  _EditableField(
    this.label,
    this.controller,
    this.onChanged, {
    this.isLast = false,
    this.readOnly = false,
  });
}
