import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/settings_service.dart';
import '../../services/storage_service.dart';
import '../../utils/helpers.dart';
import '../volunteer/volunteer_shell.dart';

class CharitySettingsScreen extends StatefulWidget {
  const CharitySettingsScreen({super.key});

  @override
  State<CharitySettingsScreen> createState() => _CharitySettingsScreenState();
}

class _CharitySettingsScreenState extends State<CharitySettingsScreen> {
  late final SettingsService _settingsService;

  bool _newSignUps = true;
  bool _attendanceAlerts = true;
  bool _weeklySummary = false;

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
      final settings = await _settingsService.getCharityNotificationSettings();
      if (!mounted) return;
      setState(() {
        _newSignUps = settings['new_sign_ups'] ?? true;
        _attendanceAlerts = settings['attendance_alerts'] ?? true;
        _weeklySummary = settings['weekly_summary'] ?? false;
      });
    } catch (_) {
      // Use defaults silently
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _settingsService.updateCharityNotificationSettings({
        'new_sign_ups': _newSignUps,
        'attendance_alerts': _attendanceAlerts,
        'weekly_summary': _weeklySummary,
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
            left: -295,
            top: -261,
            width: 894,
            height: 1308,
            child: SvgPicture.asset(
              'assets/images/home_bg_blob.svg',
              fit: BoxFit.fill,
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildDarkHeader(context)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TODO: Uncomment when admin management features are ready
                      // _buildSectionLabel('ACCOUNT'),
                      // const SizedBox(height: 10),
                      // _buildSettingsCard([
                      //   _SettingsItem(
                      //     icon: IconlyLight.user_1,
                      //     title: 'Manage Admin Users',
                      //     onTap: () {},
                      //   ),
                      //   _SettingsItem(
                      //     icon: IconlyLight.shield_done,
                      //     title: 'Permissions & Roles',
                      //     onTap: () {},
                      //   ),
                      // ]),
                      // const SizedBox(height: 20),
                      _buildSectionLabel('HELP & SUPPORT'),
                      const SizedBox(height: 10),
                      _buildSettingsCard([
                        _SettingsItem(
                          icon: IconlyLight.chat,
                          title: 'Contact Support',
                          onTap: _showContactSupportDialog,
                        ),
                        // TODO: Uncomment when FAQ page is ready
                        // _SettingsItem(
                        //   icon: IconlyLight.info_circle,
                        //   title: 'FAQ',
                        //   onTap: () {},
                        // ),
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionLabel('NOTIFICATIONS'),
                      const SizedBox(height: 10),
                      _buildNotificationsCard(),
                      const SizedBox(height: 20),
                      _buildSwitchDashboardButton(),
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
        ],
      ),
    );
  }

  // ─── Dark Header ──────────────────────────────────────────────────

  Widget _buildDarkHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 147,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -0.5),
          end: Alignment(1, 1),
          colors: [Color(0xFF262222), Color(0xFF0D0808)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Navigator.of(context).canPop()) ...[
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
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
                  child: const Icon(
                    IconlyLight.arrow_left,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 15),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 26.923 / 18,
                  ),
                ),
                Text(
                  'Manage your account preferences',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white,
                    height: 15.385 / 10,
                  ),
                ),
              ],
            ),
          ],
        ),
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
          BoxShadow(
            color: Color(0x1C000000),
            blurRadius: 19.411,
            offset: Offset(0, 2.803),
          ),
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
                        bottom: BorderSide(
                          color: const Color(
                            0xFF262222,
                          ).withValues(alpha: 0.05),
                          width: 0.923,
                        ),
                      ),
                    ),
              padding: const EdgeInsets.symmetric(horizontal: 14.77),
              child: Row(
                children: [
                  // Icon circle
                  Container(
                    width: 29.533,
                    height: 29.533,
                    decoration: BoxDecoration(
                      color: const Color(0xFF262222).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18.458),
                    ),
                    child: Icon(
                      item.icon,
                      size: 14.766,
                      color: const Color(0xFF262222),
                    ),
                  ),
                  const SizedBox(width: 11),
                  // Title
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 11.927,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF262222),
                        height: 18.458 / 11.927,
                      ),
                    ),
                  ),
                  // Chevron
                  Icon(
                    IconlyLight.arrow_right_2,
                    size: 14.766,
                    color: const Color(0xFF262222).withValues(alpha: 0.4),
                  ),
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
          BoxShadow(
            color: Color(0x1C000000),
            blurRadius: 19.411,
            offset: Offset(0, 2.803),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildToggleRow(
            icon: IconlyLight.notification,
            title: 'New Volunteer Sign-ups',
            subtitle: 'Get notified when sign-ups',
            value: _newSignUps,
            onChanged: (v) {
              setState(() => _newSignUps = v);
              _saveSettings();
            },
            showBorder: true,
          ),
          _buildToggleRow(
            icon: IconlyLight.notification,
            title: 'Attendance Alerts',
            subtitle: 'Get attendance alerts',
            value: _attendanceAlerts,
            onChanged: (v) {
              setState(() => _attendanceAlerts = v);
              _saveSettings();
            },
            showBorder: true,
          ),
          _buildToggleRow(
            icon: IconlyLight.notification,
            title: 'Weekly Summary Report',
            subtitle: 'When hours are confirmed',
            value: _weeklySummary,
            onChanged: (v) {
              setState(() => _weeklySummary = v);
              _saveSettings();
            },
            showBorder: false,
          ),
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
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF262222).withValues(alpha: 0.05),
                  width: 0.923,
                ),
              ),
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
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11.927,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF262222),
                    height: 18.458 / 11.927,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 9.939,
                    color: const Color(0xFF262222).withValues(alpha: 0.5),
                    height: 14.766 / 9.939,
                  ),
                ),
              ],
            ),
          ),
          // Custom toggle
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 40.607,
              height: 22.149,
              decoration: BoxDecoration(
                color: value
                    ? const Color(0xFFF4A583)
                    : const Color(0xFF262222).withValues(alpha: 0.05),
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
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 1.846,
                        offset: const Offset(0, 0.923),
                      ),
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

  // ─── Switch to Dashboard ──────────────────────────────────────────

  Widget _buildSwitchDashboardButton() {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthProvider>().switchMode(mode: 'volunteer');
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (_) => const VolunteerShell()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 69,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C000000),
              blurRadius: 18.944,
              offset: Offset(0, 2.735),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14.82),
            Container(
              width: 37.143,
              height: 37.143,
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
                    'Switch to Volunteer Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 13.914,
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

  // ─── Contact Support ─────────────────────────────────────────────

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
                await _settingsService.sendSupportMessage(subject: subject, message: message);
                if (mounted) {
                  Helpers.showSnackBar(context, message: 'Message sent successfully', backgroundColor: const Color(0xFF15B789));
                }
              } catch (e) {
                if (mounted) {
                  Helpers.showSnackBar(context, message: 'Failed to send message');
                }
              }
            },
            child: Text('Send', style: GoogleFonts.inter(color: const Color(0xFFF4A583), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

  // ─── Sign Out ─────────────────────────────────────────────────────

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthProvider>().logout();
        if (!mounted) return;
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/login', (_) => false);
      },
      child: Container(
        width: double.infinity,
        height: 53.528,
        decoration: BoxDecoration(
          color: const Color(0xFFE41212).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: const Color(0xFFE41212).withValues(alpha: 0.3),
            width: 0.994,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C000000),
              blurRadius: 19.411,
              offset: Offset(0, 2.803),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.logout, size: 16.612, color: const Color(0xFFE41212)),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontSize: 13.914,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE41212),
              ),
            ),
          ],
        ),
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
