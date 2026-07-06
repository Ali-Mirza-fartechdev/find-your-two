import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../utils/helpers.dart';
import 'opportunity_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _typeEmojis = {
    'event_tomorrow': '📅',
    'attendance_verified': '✅',
    'new_opportunity_nearby': '🌟',
    'achievement_unlocked': '🏆',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _onNotificationTap(AppNotification notification) async {
    final provider = context.read<NotificationProvider>();
    if (notification.isUnread) {
      provider.markAsRead(notification.id);
    }

    if (notification.relatedId != null) {
      final type = notification.type;
      if (type == 'event_tomorrow' ||
          type == 'attendance_verified' ||
          type == 'new_opportunity_nearby') {
        final oppProvider = context.read<OpportunityProvider>();
        await oppProvider.fetchOpportunityById(notification.relatedId!);
        if (!mounted) return;
        final opp = oppProvider.selectedOpportunity;
        if (opp != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OpportunityDetailScreen(opportunity: opp),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    final provider = context.read<NotificationProvider>();
    await provider.deleteNotification(notification.id);
    if (!mounted) return;
    if (provider.errorMessage != null) {
      Helpers.showSnackBar(context, message: provider.errorMessage!);
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

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
            child: provider.isLoading && provider.notifications.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildHeader(provider),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFF4A583)),
                        ),
                      ),
                    ],
                  )
                : provider.notifications.isEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildHeader(provider),
                              ],
                            ),
                          ),
                          Expanded(child: _buildEmptyState()),
                        ],
                      )
                    : RefreshIndicator(
                        color: const Color(0xFFF4A583),
                        onRefresh: () =>
                            provider.fetchNotifications(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          itemCount: provider.notifications.length + 2,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 30),
                                child: _buildHeader(provider),
                              );
                            }
                            if (index == provider.notifications.length + 1) {
                              return const SizedBox(height: 150);
                            }
                            final notification =
                                provider.notifications[index - 1];
                            return _buildNotificationCard(notification);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(NotificationProvider provider) {
    final canPop = Navigator.of(context).canPop();

    return Row(
      children: [
        if (canPop) ...[
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
                  width: 0.7,
                ),
              ),
              child: const Icon(IconlyLight.arrow_left,
                  size: 16, color: Color(0xFF262222)),
            ),
          ),
          const SizedBox(width: 15),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
            Text(
              '${provider.unreadCount} unread',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF262222),
              ),
            ),
          ],
        ),
        const Spacer(),
        if (provider.unreadCount > 0)
          GestureDetector(
            onTap: () => provider.markAllAsRead(),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF262222).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(68),
                border: Border.all(
                  color: const Color(0xFF262222).withValues(alpha: 0.6),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(IconlyLight.tick_square, size: 11, color: Color(0xFF262222)),
                  const SizedBox(width: 3),
                  Text(
                    'Mark all read',
                    style: GoogleFonts.inter(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF262222),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final emoji = _typeEmojis[notification.type] ?? '🔔';
    final isUnread = notification.isUnread;
    final timeAgo = notification.createdAt != null
        ? Helpers.timeAgo(notification.createdAt!)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _deleteNotification(notification),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(IconlyLight.delete, color: Color(0xFFE53935)),
        ),
        child: GestureDetector(
          onTap: () => _onNotificationTap(notification),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isUnread
                  ? const Color(0xFFF4A583).withValues(alpha: 0.2)
                  : Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 41,
                  height: 41,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF4A583).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 18.6)),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isUnread
                              ? const Color(0xFF262222)
                              : const Color(0xFF262222)
                                  .withValues(alpha: 0.8),
                        ),
                      ),
                      if (notification.body != null &&
                          notification.body!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          notification.body!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF262222)
                                .withValues(alpha: 0.5),
                            height: 15 / 10,
                          ),
                        ),
                      ],
                      if (timeAgo.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 9.3,
                            color: const Color(0xFF262222)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isUnread)
                  Container(
                    width: 7.4,
                    height: 7.4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4A583),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            IconlyLight.notification,
            size: 48,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF262222),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You'll be notified about events and achievements",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
