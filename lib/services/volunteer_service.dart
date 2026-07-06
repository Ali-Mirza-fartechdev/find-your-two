import '../config/api_endpoints.dart';
import 'api_service.dart';

/// Impact response from GET /impact containing all sections:
/// summary, impact_score, monthly_hours, achievements
class ImpactData {
  final Map<String, dynamic> summary;
  final Map<String, dynamic> impactScore;
  final List<Map<String, dynamic>> monthlyHours;
  final List<Map<String, dynamic>> achievements;

  const ImpactData({
    required this.summary,
    required this.impactScore,
    required this.monthlyHours,
    required this.achievements,
  });

  factory ImpactData.fromJson(Map<String, dynamic> json) {
    return ImpactData(
      summary: json['summary'] as Map<String, dynamic>? ?? {},
      impactScore: json['impact_score'] as Map<String, dynamic>? ?? {},
      monthlyHours: (json['monthly_hours'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [],
      achievements: (json['achievements'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [],
    );
  }
}

class VolunteerService {
  final ApiService _apiService;

  VolunteerService({required ApiService apiService})
      : _apiService = apiService;

  /// GET /impact → all impact data in one call
  Future<ImpactData> getImpact() async {
    final response = await _apiService.get(ApiEndpoints.impact);
    return ImpactData.fromJson(response as Map<String, dynamic>);
  }

  /// GET /impact/monthly (standalone, if needed separately)
  Future<List<Map<String, dynamic>>> getMonthlyImpact({int? year}) async {
    final queryParams = <String, String>{};
    if (year != null) queryParams['year'] = year.toString();

    final response = await _apiService.get(
      ApiEndpoints.impactMonthly,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    final list = response as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /achievements (standalone, if needed separately)
  Future<List<Map<String, dynamic>>> getAchievements() async {
    final response = await _apiService.get(ApiEndpoints.achievements);
    final list = response as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }
}
