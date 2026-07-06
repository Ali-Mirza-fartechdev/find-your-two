import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../../models/group.dart';
import '../../../providers/group_provider.dart';
import '../../../utils/helpers.dart';
import 'invite_member_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchGroupDetail(widget.groupId);
    });
  }

  Future<void> _handleLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Leave Group',
          style: GoogleFonts.ptSerif(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF262222),
          ),
        ),
        content: Text(
          'Are you sure you want to leave this group?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF262222).withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF262222).withValues(alpha: 0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Leave',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE53935),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<GroupProvider>();
    final success = await provider.leaveGroup(widget.groupId);

    if (!mounted) return;
    if (success) {
      Helpers.showSnackBar(
        context,
        message: 'Left group',
        backgroundColor: const Color(0xFF15B789),
      );
      Navigator.of(context).pop();
    } else {
      Helpers.showSnackBar(
        context,
        message: provider.errorMessage ?? 'Failed to leave group',
      );
      provider.clearError();
    }
  }

  Future<void> _handleRemoveMember(GroupMember member) async {
    final name = member.name ?? member.email ?? 'this member';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Remove Member',
          style: GoogleFonts.ptSerif(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF262222),
          ),
        ),
        content: Text(
          'Remove $name from the group?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF262222).withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF262222).withValues(alpha: 0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remove',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE53935),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<GroupProvider>();
    final success = await provider.removeMember(widget.groupId, member.id);

    if (!mounted) return;
    if (success) {
      Helpers.showSnackBar(
        context,
        message: 'Member removed',
        backgroundColor: const Color(0xFF15B789),
      );
    } else {
      Helpers.showSnackBar(
        context,
        message: provider.errorMessage ?? 'Failed to remove member',
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupProvider>();
    final group = provider.selectedGroup;

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
            child: provider.isLoading && group == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF4A583),
                    ),
                  )
                : group == null
                    ? _buildErrorState(provider)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(group),
                          const SizedBox(height: 20),
                          _buildMemberCount(group),
                          const SizedBox(height: 16),
                          Expanded(
                            child: RefreshIndicator(
                              color: const Color(0xFFF4A583),
                              onRefresh: () async {
                                await provider
                                    .fetchGroupDetail(widget.groupId);
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    25, 0, 25, 150),
                                itemCount: group.members.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 1),
                                itemBuilder: (context, index) {
                                  return _buildMemberTile(
                                      group, group.members[index]);
                                },
                              ),
                            ),
                          ),
                          if (!group.isOwner)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(25, 0, 25, 20),
                              child: SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton(
                                  onPressed: _handleLeave,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFFE53935)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  child: Text(
                                    'Leave Group',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE53935),
                                    ),
                                  ),
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

  Widget _buildHeader(Group group) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        group.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF262222),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (group.isOwner) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFF4A583).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Owner',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF4A583),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (group.isOwner)
            GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        InviteMemberScreen(groupId: widget.groupId),
                  ),
                );
                if (mounted) {
                  context
                      .read<GroupProvider>()
                      .fetchGroupDetail(widget.groupId);
                }
              },
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A583),
                  borderRadius: BorderRadius.circular(58),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Invite',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberCount(Group group) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Text(
        '${group.members.length} member${group.members.length != 1 ? 's' : ''}',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF262222).withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildMemberTile(Group group, GroupMember member) {
    final isInvited = member.isInvited;
    final displayName = member.name ?? member.email ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF262222).withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isInvited
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFF4A583).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty
                    ? displayName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isInvited
                      ? const Color(0xFF92400E)
                      : const Color(0xFFF4A583),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF262222),
                  ),
                ),
                if (isInvited)
                  Text(
                    'Invite pending',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF92400E),
                    ),
                  )
                else if (member.email != null)
                  Text(
                    member.email!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF262222).withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          if (group.isOwner)
            GestureDetector(
              onTap: () => _handleRemoveMember(member),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.close, size: 14, color: Color(0xFFE53935)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(GroupProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(IconlyLight.danger, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            provider.errorMessage ?? 'Could not load group',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () =>
                context.read<GroupProvider>().fetchGroupDetail(widget.groupId),
            child: Text(
              'Try Again',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF4A583),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
