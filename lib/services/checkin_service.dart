import '../config/api_endpoints.dart';
import 'api_service.dart';

class CheckinResult {
  final bool checkedIn;
  final String? checkedInAt;
  final String? checkInMethod;
  final double hoursAwarded;
  final Map<String, dynamic>? impactUpdate;

  const CheckinResult({
    required this.checkedIn,
    this.checkedInAt,
    this.checkInMethod,
    required this.hoursAwarded,
    this.impactUpdate,
  });

  factory CheckinResult.fromJson(Map<String, dynamic> json) {
    return CheckinResult(
      checkedIn: json['checked_in'] as bool? ?? false,
      checkedInAt: json['checked_in_at'] as String?,
      checkInMethod: json['check_in_method'] as String?,
      hoursAwarded: (json['hours_awarded'] as num?)?.toDouble() ?? 0,
      impactUpdate: json['impact_update'] as Map<String, dynamic>?,
    );
  }
}

class CheckinService {
  final ApiService _apiService;

  CheckinService({required ApiService apiService}) : _apiService = apiService;

  Future<CheckinResult> checkinViaQr(int opportunityId, String qrToken) async {
    final response = await _apiService.post(
      ApiEndpoints.checkinQr(opportunityId),
      body: {'qr_token': qrToken},
    );
    return CheckinResult.fromJson(response as Map<String, dynamic>);
  }

  Future<CheckinResult> checkinViaGps(
    int opportunityId, {
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.checkinGps(opportunityId),
      body: {'latitude': latitude, 'longitude': longitude},
    );
    return CheckinResult.fromJson(response as Map<String, dynamic>);
  }

  Future<CheckinResult> getCheckinStatus(int opportunityId) async {
    final response = await _apiService.get(
      ApiEndpoints.checkinStatus(opportunityId),
    );
    return CheckinResult.fromJson(response as Map<String, dynamic>);
  }
}
