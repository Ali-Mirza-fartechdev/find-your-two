import '../config/api_endpoints.dart';
import '../models/app_notification.dart';
import 'api_service.dart';

class NotificationResult {
  final int unreadCount;
  final List<AppNotification> data;

  const NotificationResult({
    required this.unreadCount,
    required this.data,
  });
}

class NotificationService {
  final ApiService _apiService;

  NotificationService({required ApiService apiService})
      : _apiService = apiService;

  /// GET /notifications → { unread_count, data: [...] }
  Future<NotificationResult> getNotifications() async {
    final response = await _apiService.get(ApiEndpoints.notifications);

    final map = response as Map<String, dynamic>;
    final list = (map['data'] as List<dynamic>?) ?? [];

    return NotificationResult(
      unreadCount: map['unread_count'] as int? ?? 0,
      data: list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> markAsRead(int notificationId) async {
    await _apiService.put(ApiEndpoints.notificationRead(notificationId));
  }

  Future<void> markAllAsRead() async {
    await _apiService.put(ApiEndpoints.notificationsReadAll);
  }

  Future<void> deleteNotification(int notificationId) async {
    await _apiService.delete(ApiEndpoints.notificationDelete(notificationId));
  }
}
