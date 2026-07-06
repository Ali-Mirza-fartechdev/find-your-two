import '../config/api_endpoints.dart';
import 'api_service.dart';

class DeviceService {
  final ApiService _apiService;

  DeviceService({required ApiService apiService}) : _apiService = apiService;

  /// POST /devices — register FCM token for push notifications
  Future<void> registerDevice({required String fcmToken}) async {
    await _apiService.post(
      ApiEndpoints.devices,
      body: {'fcm_token': fcmToken},
    );
  }

  /// DELETE /devices/{token} — unregister device
  Future<void> unregisterDevice({required String fcmToken}) async {
    await _apiService.delete(ApiEndpoints.deviceDelete(fcmToken));
  }
}
