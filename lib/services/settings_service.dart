import '../config/api_endpoints.dart';
import 'api_service.dart';

class SettingsService {
  final ApiService _apiService;

  SettingsService({required ApiService apiService}) : _apiService = apiService;

  /// GET /settings/notifications — volunteer notification preferences
  Future<Map<String, bool>> getNotificationSettings() async {
    final response = await _apiService.get(ApiEndpoints.settingsNotifications);
    final data = response as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(key, value as bool? ?? false));
  }

  /// PUT /settings/notifications — update volunteer notification preferences
  Future<Map<String, bool>> updateNotificationSettings(
      Map<String, bool> settings) async {
    final response = await _apiService.put(
      ApiEndpoints.settingsNotifications,
      body: settings.map((key, value) => MapEntry(key, value)),
    );
    final data = response as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(key, value as bool? ?? false));
  }

  /// GET /charity/settings/notifications — charity notification preferences
  Future<Map<String, bool>> getCharityNotificationSettings() async {
    final response =
        await _apiService.get(ApiEndpoints.charitySettingsNotifications);
    final data = response as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(key, value as bool? ?? false));
  }

  /// PUT /charity/settings/notifications — update charity notification preferences
  Future<Map<String, bool>> updateCharityNotificationSettings(
      Map<String, bool> settings) async {
    final response = await _apiService.put(
      ApiEndpoints.charitySettingsNotifications,
      body: settings.map((key, value) => MapEntry(key, value)),
    );
    final data = response as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(key, value as bool? ?? false));
  }

  /// PUT /settings/email — change email (requires password)
  Future<void> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    await _apiService.put(
      ApiEndpoints.settingsEmail,
      body: {
        'new_email': newEmail,
        'current_password': currentPassword,
      },
    );
  }

  /// PUT /settings/password — change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _apiService.put(
      ApiEndpoints.settingsPassword,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  /// POST /support/contact — send support message
  Future<void> sendSupportMessage({
    required String subject,
    required String message,
  }) async {
    await _apiService.post(
      ApiEndpoints.supportContact,
      body: {
        'subject': subject,
        'message': message,
      },
    );
  }
}
