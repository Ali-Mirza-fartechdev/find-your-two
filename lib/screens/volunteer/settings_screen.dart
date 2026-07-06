import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/settings_service.dart';
import '../../services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/helpers.dart';
import '../charity/charity_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _settingsService;

  bool _isLoadingSettings = true;
  bool _eventReminders = true;
  bool _nearbyOpportunities = true;
  bool _attendanceVerified = true;
  bool _achievements = false;
  bool _monthlyNewsletter = false;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService(
      apiService: ApiService(storageService: StorageService()),
    );
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getNotificationSettings();
      if (!mounted) return;
      setState(() {
        _eventReminders = settings['event_reminders'] ?? true;
        _nearbyOpportunities = settings['nearby_opportunities'] ?? true;
        _attendanceVerified = settings['attendance_verified'] ?? true;
        _achievements = settings['achievements'] ?? false;
        _monthlyNewsletter = settings['monthly_newsletter'] ?? false;
        _isLoadingSettings = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      await _settingsService.updateNotificationSettings({
        'event_reminders': _eventReminders,
        'nearby_opportunities': _nearbyOpportunities,
        'attendance_verified': _attendanceVerified,
        'achievements': _achievements,
        'monthly_newsletter': _monthlyNewsletter,
      });
    } catch (_) {
      // Silently fail — toggles reflect local state
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: -295, top: -261, width: 894, height: 1308,
            child: SvgPicture.asset('assets/images/home_bg_blob.svg', fit: BoxFit.fill),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account
                        _buildSectionLabel('ACCOUNT'),
                        const SizedBox(height: 10),
                        _buildSettingsCard([
                          _SettingsItem(icon: IconlyLight.message, title: 'Change Email', onTap: _showChangeEmailDialog),
                          _SettingsItem(icon: IconlyLight.lock, title: 'Change Password', onTap: _showChangePasswordDialog),
                          _SettingsItem(icon: IconlyLight.profile, title: 'Edit Profile', onTap: () {
                            // Navigate to profile tab — pop back to shell
                            Navigator.of(context).pop();
                          }),
                          _SettingsItem(icon: IconlyLight.shield_done, title: 'Privacy Settings', onTap: () {
                            _launchUrl('https://findyourtwo.org/privacy-policy');
                          }),
                        ]),
                        const SizedBox(height: 20),
                        // Help & Support
                        _buildSectionLabel('HELP & SUPPORT'),
                        const SizedBox(height: 10),
                        _buildSettingsCard([
                          _SettingsItem(icon: IconlyLight.chat, title: 'Contact Support', onTap: _showContactSupportDialog),
                          // TODO: Uncomment when FAQ page is ready
                          // _SettingsItem(icon: IconlyLight.info_circle, title: 'FAQ', onTap: () {
                          //   _launchUrl('https://findyourtwo.org/faq');
                          // }),
                        ]),
                        const SizedBox(height: 20),
                        // Notifications
                        _buildSectionLabel('NOTIFICATIONS'),
                        const SizedBox(height: 10),
                        if (_isLoadingSettings)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator(color: Color(0xFFF4A583), strokeWidth: 2)),
                          )
                        else
                          _buildNotificationsCard(),
                        const SizedBox(height: 20),
                        _buildSwitchCharityButton(),
                        const SizedBox(height: 20),
                        _buildSignOutButton(),
                        const SizedBox(height: 12),
                        _buildDeleteAccountButton(),
                        const SizedBox(height: 150),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF262222).withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF262222).withValues(alpha: 0.6),
                  width: 0.685,
                ),
              ),
              child: const Icon(IconlyLight.arrow_left, size: 16, color: Color(0xFF262222)),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF262222), height: 26.923 / 18)),
              Text('Manage your account preferences',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF262222), height: 15.385 / 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section Label ────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9.939,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF262222).withValues(alpha: 0.7),
          letterSpacing: 0.554,
        ),
      ),
    );
  }

  // ─── Settings Card ────────────────────────────────────────────────

  Widget _buildSettingsCard(List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.908),
        boxShadow: const [
          BoxShadow(color: Color(0x1C000000), blurRadius: 19.411, offset: Offset(0, 2.803)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;
          return GestureDetector(
            onTap: item.onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 56.296,
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.05), width: 0.923),
                      ),
                    ),
              padding: const EdgeInsets.symmetric(horizontal: 14.77),
              child: Row(
                children: [
                  Container(
                    width: 29.533,
                    height: 29.533,
                    decoration: BoxDecoration(
                      color: const Color(0xFF262222).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18.458),
                    ),
                    child: Icon(item.icon, size: 14.766, color: const Color(0xFF262222)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(item.title,
                        style: GoogleFonts.inter(fontSize: 11.927, fontWeight: FontWeight.bold, color: const Color(0xFF262222), height: 18.458 / 11.927)),
                  ),
                  Icon(IconlyLight.arrow_right_2, size: 14.766, color: const Color(0xFF262222).withValues(alpha: 0.4)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Notifications Card ───────────────────────────────────────────

  Widget _buildNotificationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.908),
        boxShadow: const [
          BoxShadow(color: Color(0x1C000000), blurRadius: 19.411, offset: Offset(0, 2.803)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildToggleRow(icon: IconlyLight.notification, title: 'Event Reminders', subtitle: 'Get notified before events',
              value: _eventReminders, onChanged: (v) { setState(() => _eventReminders = v); _saveNotificationSettings(); }, showBorder: true),
          _buildToggleRow(icon: IconlyLight.location, title: 'Nearby Opportunities', subtitle: 'New events close to you',
              value: _nearbyOpportunities, onChanged: (v) { setState(() => _nearbyOpportunities = v); _saveNotificationSettings(); }, showBorder: true),
          _buildToggleRow(icon: IconlyLight.shield_done, title: 'Attendance Verified', subtitle: 'When hours are confirmed',
              value: _attendanceVerified, onChanged: (v) { setState(() => _attendanceVerified = v); _saveNotificationSettings(); }, showBorder: true),
          _buildToggleRow(icon: IconlyLight.star, title: 'Achievements', subtitle: 'Unlock new badges',
              value: _achievements, onChanged: (v) { setState(() => _achievements = v); _saveNotificationSettings(); }, showBorder: true),
          _buildToggleRow(icon: IconlyLight.paper, title: 'Monthly Newsletter', subtitle: 'Community highlights',
              value: _monthlyNewsletter, onChanged: (v) { setState(() => _monthlyNewsletter = v); _saveNotificationSettings(); }, showBorder: false),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool showBorder,
  }) {
    return Container(
      height: 59.988,
      decoration: showBorder
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.05), width: 0.923)),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 14.77),
      child: Row(
        children: [
          Container(
            width: 29.533,
            height: 29.533,
            decoration: BoxDecoration(
              color: const Color(0xFF262222).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18.458),
            ),
            child: Icon(icon, size: 13.843, color: const Color(0xFF262222)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(fontSize: 11.927, fontWeight: FontWeight.bold, color: const Color(0xFF262222), height: 18.458 / 11.927)),
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 9.939, color: const Color(0xFF262222).withValues(alpha: 0.5), height: 14.766 / 9.939)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 40.607,
              height: 22.149,
              decoration: BoxDecoration(
                color: value ? const Color(0xFFF4A583) : const Color(0xFF262222).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(9228),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14.766,
                  height: 14.766,
                  margin: const EdgeInsets.symmetric(horizontal: 3.69),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 1.846, offset: const Offset(0, 0.923)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Switch to Charity Dashboard ──────────────────────────────────

  Widget _buildSwitchCharityButton() {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthProvider>().switchMode(mode: 'charity');
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (_) => const CharityShell()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 69,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [
            BoxShadow(color: Color(0x1C000000), blurRadius: 19.411, offset: Offset(0, 2.803)),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14.79),
            Container(
              width: 37.143,
              height: 37.143,
              decoration: BoxDecoration(
                color: const Color(0xFF262222).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset('assets/icons/volunteer_mode.svg', width: 18, height: 11),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Switch to Charity Dashboard',
                      style: GoogleFonts.inter(fontSize: 13.914, fontWeight: FontWeight.bold, color: const Color(0xFF262222))),
                  Text('Manage your organisation & events',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF65758B))),
                ],
              ),
            ),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }

  // ─── Sign Out ─────────────────────────────────────────────────────

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthProvider>().logout();
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil('/login', (_) => false);
      },
      child: Container(
        width: double.infinity,
        height: 53.528,
        decoration: BoxDecoration(
          color: const Color(0xFFE41212).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFFE41212).withValues(alpha: 0.3), width: 0.994),
          boxShadow: const [
            BoxShadow(color: Color(0x1C000000), blurRadius: 19.411, offset: Offset(0, 2.803)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.logout, size: 16.612, color: const Color(0xFFE41212)),
            const SizedBox(width: 8),
            Text('Sign Out',
                style: GoogleFonts.inter(fontSize: 13.914, fontWeight: FontWeight.bold, color: const Color(0xFFE41212))),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Delete Account ──────────────────────────────────────────────

  Widget _buildDeleteAccountButton() {
    return GestureDetector(
      onTap: _showDeleteAccountDialog,
      child: Container(
        width: double.infinity,
        height: 53.528,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: const Color(0xFFE41212).withValues(alpha: 0.3),
            width: 0.994,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.delete, size: 16.612, color: const Color(0xFFE41212).withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text('Delete Account',
                style: GoogleFonts.inter(fontSize: 13.914, fontWeight: FontWeight.bold, color: const Color(0xFFE41212).withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFE41212))),
        content: Text(
          'This will permanently delete your account, including both your volunteer and charity profiles. All your data, enrolled opportunities, and impact history will be lost.\n\nThis action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF262222).withValues(alpha: 0.7), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF262222).withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final authProvider = context.read<AuthProvider>();
              final success = await authProvider.deleteAccount();
              if (!mounted) return;
              if (success) {
                Navigator.of(context, rootNavigator: true)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              } else {
                Helpers.showSnackBar(context,
                    message: authProvider.errorMessage ?? 'Failed to delete account');
              }
            },
            child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFE41212), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────

  void _showChangeEmailDialog() {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Email',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF262222))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF262222)),
              decoration: InputDecoration(
                labelText: 'New Email',
                labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF262222).withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF4A583))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF262222)),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF262222).withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF4A583))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF262222).withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              final password = passwordCtrl.text.trim();
              if (email.isEmpty || password.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await _settingsService.changeEmail(
                  newEmail: email,
                  currentPassword: password,
                );
                if (mounted) {
                  Helpers.showSnackBar(context,
                      message: 'Email updated successfully',
                      backgroundColor: const Color(0xFF15B789));
                }
              } catch (e) {
                if (mounted) {
                  Helpers.showSnackBar(context,
                      message: e is ApiException ? e.message : 'Failed to update email');
                }
              }
            },
            child: Text('Save', style: GoogleFonts.inter(color: const Color(0xFFF4A583), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Password',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF262222))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF262222)),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF262222).withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF4A583))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF262222)),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF262222).withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF4A583))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF262222)),
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF262222).withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF4A583))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF262222).withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              final current = currentCtrl.text.trim();
              final newPass = newCtrl.text.trim();
              final confirm = confirmCtrl.text.trim();
              if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) return;
              if (newPass != confirm) {
                Helpers.showSnackBar(context, message: 'Passwords do not match');
                return;
              }
              Navigator.of(ctx).pop();
              try {
                await _settingsService.changePassword(
                  currentPassword: current,
                  newPassword: newPass,
                  confirmPassword: confirm,
                );
                if (mounted) {
                  Helpers.showSnackBar(context,
                      message: 'Password updated successfully',
                      backgroundColor: const Color(0xFF15B789));
                }
              } catch (e) {
                if (mounted) {
                  Helpers.showSnackBar(context,
                      message: e is ApiException ? e.message : 'Failed to update password');
                }
              }
            },
            child: Text('Save', style: GoogleFonts.inter(color: const Color(0xFFF4A583), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showContactSupportDialog() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Contact Support',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF262222))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectCtrl,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF262222)),
              decoration: InputDecoration(
                labelText: 'Subject',
                labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF262222).withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF4A583))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 4,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF262222)),
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF262222).withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF262222).withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF4A583))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF262222).withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              final subject = subjectCtrl.text.trim();
              final message = messageCtrl.text.trim();
              if (subject.isEmpty || message.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await _settingsService.sendSupportMessage(
                  subject: subject,
                  message: message,
                );
                if (mounted) {
                  Helpers.showSnackBar(context,
                      message: 'Message sent successfully',
                      backgroundColor: const Color(0xFF15B789));
                }
              } catch (e) {
                if (mounted) {
                  Helpers.showSnackBar(context,
                      message: e is ApiException ? e.message : 'Failed to send message');
                }
              }
            },
            child: Text('Send', style: GoogleFonts.inter(color: const Color(0xFFF4A583), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _SettingsItem({required this.icon, required this.title, required this.onTap});
}
