import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  static void showSnackBar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    final topPadding = MediaQuery.of(context).padding.top;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: backgroundColor ?? const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height -
              topPadding -
              kToolbarHeight -
              40,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
        dismissDirection: DismissDirection.up,
      ),
    );
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy · h:mm a').format(date);
  }

  static String formatHours(double hours) {
    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Parse API datetime string "2026-05-01 09:00:00" → DateTime
  static DateTime? parseApiDatetime(String? datetime) {
    if (datetime == null || datetime.isEmpty) return null;
    return DateTime.tryParse(datetime.replaceFirst(' ', 'T'));
  }

  /// Format API datetime to short date: "Tue, May 1"
  static String formatApiDate(String? datetime) {
    final dt = parseApiDatetime(datetime);
    if (dt == null) return '';
    return DateFormat('EEE, MMM d').format(dt);
  }

  /// Format API datetime to time: "9:00 AM"
  static String formatApiTime(String? datetime) {
    final dt = parseApiDatetime(datetime);
    if (dt == null) return '';
    return DateFormat('h:mm a').format(dt);
  }

  /// Format time range from start and end: "9:00 AM - 1:00 PM"
  static String formatApiTimeRange(String? start, String? end) {
    final s = formatApiTime(start);
    final e = formatApiTime(end);
    if (s.isEmpty && e.isEmpty) return '';
    if (e.isEmpty) return s;
    return '$s - $e';
  }

  /// Duration string from start/end datetimes: "4 Hours"
  static String formatDuration(String? start, String? end) {
    final s = parseApiDatetime(start);
    final e = parseApiDatetime(end);
    if (s == null || e == null) return '';
    final hours = e.difference(s).inHours;
    if (hours <= 0) return '';
    if (hours == 1) return '1 Hour';
    if (hours > 6) return 'Full Day';
    return '$hours Hours';
  }

  /// Format distance: 2.4 → "2.4 km", null → ""
  static String formatDistance(double? km) {
    if (km == null) return '';
    if (km < 0.1) return '< 0.1 km';
    return '${km.toStringAsFixed(1)} km';
  }
}
