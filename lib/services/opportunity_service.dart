import '../config/api_endpoints.dart';
import '../config/constants.dart';
import '../models/opportunity.dart';
import 'api_service.dart';

class PaginatedOpportunities {
  final List<Opportunity> data;
  final int total;
  final int page;
  final int perPage;

  const PaginatedOpportunities({
    required this.data,
    required this.total,
    required this.page,
    required this.perPage,
  });
}

class MyOpportunitiesResult {
  final int upcomingCount;
  final int pastCount;
  final List<Map<String, dynamic>> data;

  const MyOpportunitiesResult({
    required this.upcomingCount,
    required this.pastCount,
    required this.data,
  });
}

class OpportunityService {
  final ApiService _apiService;

  OpportunityService({required ApiService apiService})
      : _apiService = apiService;

  /// GET /opportunities → { data: [...], pagination: { page, per_page, total } }
  Future<PaginatedOpportunities> getOpportunities({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
    String? category,
    List<String>? categories,
    String? search,
    bool? kidsOk,
    bool? acceptsGroups,
    List<String>? daysOfWeek,
    List<String>? timesOfDay,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    // Single category (backwards compatible)
    if (category != null) queryParams['category'] = category;
    // Multi-select categories: comma-separated
    if (categories != null && categories.isNotEmpty) {
      queryParams['category'] = categories.join(',');
    }
    if (search != null) queryParams['search'] = search;
    if (kidsOk != null) queryParams['kids_ok'] = kidsOk ? '1' : '0';
    if (acceptsGroups == true) queryParams['accepts_groups'] = '1';
    if (daysOfWeek != null && daysOfWeek.isNotEmpty) {
      queryParams['day_of_week'] = daysOfWeek.join(',');
    }
    if (timesOfDay != null && timesOfDay.isNotEmpty) {
      queryParams['time_of_day'] = timesOfDay.join(',');
    }

    final response = await _apiService.get(
      ApiEndpoints.opportunities,
      queryParams: queryParams,
    );

    final map = response as Map<String, dynamic>;
    final list = (map['data'] as List<dynamic>?) ?? [];
    final pagination = map['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedOpportunities(
      data: list
          .map((e) => Opportunity.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination['total'] as int? ?? list.length,
      page: pagination['page'] as int? ?? page,
      perPage: pagination['per_page'] as int? ?? perPage,
    );
  }

  /// GET /opportunities/nearby → { count, data: [...] }
  /// Query params are `lat` and `lng` (not latitude/longitude).
  Future<List<Opportunity>> getNearbyOpportunities({
    required double latitude,
    required double longitude,
    double? radius,
  }) async {
    final queryParams = {
      'lat': latitude.toString(),
      'lng': longitude.toString(),
    };
    if (radius != null) queryParams['radius'] = radius.toString();

    final response = await _apiService.get(
      ApiEndpoints.nearbyOpportunities,
      queryParams: queryParams,
    );

    final map = response as Map<String, dynamic>;
    final list = (map['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => Opportunity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /opportunities/:id → full opportunity detail object
  Future<Opportunity> getOpportunityById(int id) async {
    final response = await _apiService.get(
      ApiEndpoints.opportunityById(id),
    );
    return Opportunity.fromJson(response as Map<String, dynamic>);
  }

  /// POST /opportunities → { id, status, message } (charity only)
  Future<Map<String, dynamic>> createOpportunity(
      Map<String, dynamic> data) async {
    final response = await _apiService.post(
      ApiEndpoints.opportunities,
      body: data,
    );
    return response as Map<String, dynamic>;
  }

  Future<Opportunity> updateOpportunity(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.put(
      ApiEndpoints.opportunityById(id),
      body: data,
    );
    return Opportunity.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteOpportunity(int id) async {
    await _apiService.delete(ApiEndpoints.opportunityById(id));
  }

  /// POST /opportunities/:id/enroll
  /// Requires body: { full_name, phone_number, email, party_size?, group_id? }
  Future<Map<String, dynamic>> enrollInOpportunity(
    int id, {
    required String fullName,
    required String phoneNumber,
    required String email,
    int partySize = 1,
    int? groupId,
  }) async {
    final body = <String, dynamic>{
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'party_size': partySize,
    };
    if (groupId != null) body['group_id'] = groupId;

    final response = await _apiService.post(
      ApiEndpoints.enroll(id),
      body: body,
    );
    return response as Map<String, dynamic>;
  }

  /// POST /opportunities/:id/save
  Future<Map<String, dynamic>> saveOpportunity(int id) async {
    final response = await _apiService.post(ApiEndpoints.opportunitySave(id));
    return response as Map<String, dynamic>;
  }

  /// DELETE /opportunities/:id/save
  Future<Map<String, dynamic>> unsaveOpportunity(int id) async {
    final response = await _apiService.delete(ApiEndpoints.opportunitySave(id));
    return response as Map<String, dynamic>;
  }

  /// GET /saved-opportunities — returns all saved opportunities (not paginated).
  Future<List<Opportunity>> getSavedOpportunities() async {
    final response = await _apiService.get(ApiEndpoints.savedOpportunities);
    final map = response as Map<String, dynamic>;
    final list = (map['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => Opportunity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /opportunities/:id/track-click — returns { url } to open.
  Future<String> trackClick(int id) async {
    final response = await _apiService.post(ApiEndpoints.trackClick(id));
    final map = response as Map<String, dynamic>;
    return map['url'] as String;
  }

  /// DELETE /opportunities/:id/enroll
  Future<void> withdrawFromOpportunity(int id) async {
    await _apiService.delete(ApiEndpoints.enroll(id));
  }

  /// GET /volunteer/opportunities → { upcoming_count, past_count, data: [...] }
  Future<MyOpportunitiesResult> getMyOpportunities() async {
    final response = await _apiService.get(
      ApiEndpoints.volunteerOpportunities,
    );

    final map = response as Map<String, dynamic>;
    final list = (map['data'] as List<dynamic>?) ?? [];

    return MyOpportunitiesResult(
      upcomingCount: map['upcoming_count'] as int? ?? 0,
      pastCount: map['past_count'] as int? ?? 0,
      data: list.cast<Map<String, dynamic>>(),
    );
  }
}
