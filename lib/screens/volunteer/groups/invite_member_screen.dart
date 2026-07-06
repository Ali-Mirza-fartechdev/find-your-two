import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../../providers/group_provider.dart';
import '../../../utils/helpers.dart';

class InviteMemberScreen extends StatefulWidget {
  final int groupId;

  const InviteMemberScreen({super.key, required this.groupId});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _lastInviteToken;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      Helpers.showSnackBar(context, message: 'Enter a valid email address');
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<GroupProvider>();
    final token = await provider.inviteMember(widget.groupId, email: email);

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _lastInviteToken = token;
    });

    if (token != null) {
      _emailController.clear();
      Helpers.showSnackBar(
        context,
        message: 'Invitation sent to $email',
        backgroundColor: const Color(0xFF15B789),
      );
    } else {
      Helpers.showSnackBar(
        context,
        message: provider.errorMessage ?? 'Failed to send invite',
      );
      provider.clearError();
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
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Address',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F1729).withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            cursorColor: const Color(0xFFF4A583),
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0D0808),
                            ),
                            decoration: InputDecoration(
                              hintText: 'friend@example.com',
                              hintStyle: GoogleFonts.openSans(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF0D0808)
                                    .withValues(alpha: 0.3),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'They will receive an email with an invite link to join this group.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF262222).withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleInvite,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF4A583),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFFF4A583).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Send Invite',
                                  style: GoogleFonts.ptSerif(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      if (_lastInviteToken != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15B789).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF15B789).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 18, color: Color(0xFF15B789)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Invite link sent! You can also share it manually.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF15B789),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                    text:
                                        'https://findyourtwo.org/join-group/?token=$_lastInviteToken',
                                  ));
                                  Helpers.showSnackBar(
                                    context,
                                    message: 'Invite link copied!',
                                    backgroundColor: const Color(0xFF15B789),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF15B789),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Copy',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
      child: Row(
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
              child: const Center(
                child: Icon(IconlyLight.arrow_left,
                    size: 16, color: Color(0xFF262222)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            'Invite Member',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
            ),
          ),
        ],
      ),
    );
  }
}
