import '../config/api_endpoints.dart';
import 'api_service.dart';

class CharityDashboardData {
  final String orgName;
  final int totalVolunteers;
  final int activePosts;
  final int upcoming;
  final int peopleSent;
  final List<Map<String, dynamic>> participationChart;
  final List<Map<String, dynamic>> activeOpportunities;

  CharityDashboardData({
    required this.orgName,
    required this.totalVolunteers,
    required this.activePosts,
    required this.upcoming,
    required this.peopleSent,
    required this.participationChart,
    required this.activeOpportunities,
  });

  factory CharityDashboardData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return CharityDashboardData(
      orgName: json['org_name'] as String? ?? '',
      totalVolunteers: stats['total_volunteers'] as int? ?? 0,
      activePosts: stats['active_posts'] as int? ?? 0,
      upcoming: stats['upcoming'] as int? ?? 0,
      peopleSent: stats['people_sent'] as int? ?? 0,
      participationChart: (json['participation_chart'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      activeOpportunities: (json['active_opportunities'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}

class CharityProfile {
  final int id;
  final String orgName;
  final String? email;
  final String? phone;
  final String? website;
  final String? mission;
  final String? logoUrl;
  final bool verified;
  final Map<String, String> socialLinks;

  CharityProfile({
    required this.id,
    required this.orgName,
    this.email,
    this.phone,
    this.website,
    this.mission,
    this.logoUrl,
    this.verified = false,
    this.socialLinks = const {},
  });

  factory CharityProfile.fromJson(Map<String, dynamic> json) {
    final rawSocial = json['social_links'] as Map<String, dynamic>? ?? {};
    final socialLinks = rawSocial.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
    return CharityProfile(
      id: json['id'] as int,
      orgName: json['org_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      mission: json['mission'] as String?,
      logoUrl: json['logo_url'] as String?,
      verified: json['verified'] as bool? ?? false,
      socialLinks: socialLinks,
    );
  }
}

class VolunteerAttendanceData {
  final String opportunityTitle;
  final int total;
  final int present;
  final int absent;
  final int unmarked;
  final List<AttendanceVolunteer> volunteers;

  VolunteerAttendanceData({
    required this.opportunityTitle,
    required this.total,
    required this.present,
    required this.absent,
    required this.unmarked,
    required this.volunteers,
  });

  factory VolunteerAttendanceData.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] as Map<String, dynamic>? ?? {};
    return VolunteerAttendanceData(
      opportunityTitle: json['opportunity_title'] as String? ?? '',
      total: counts['total'] as int? ?? 0,
      present: counts['present'] as int? ?? 0,
      absent: counts['absent'] as int? ?? 0,
      unmarked: counts['unmarked'] as int? ?? 0,
      volunteers: (json['volunteers'] as List<dynamic>?)
              ?.map((e) =>
                  AttendanceVolunteer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AttendanceVolunteer {
  final int participationId;
  final int volunteerId;
  final String fullName;
  final String displayName; // Pre-formatted: "John Smith +2"
  final int partySize;
  final String? avatarUrl;
  final String? attendanceStatus; // null | "present" | "absent"
  final bool checkedIn;
  final String? checkedInAt;

  AttendanceVolunteer({
    required this.participationId,
    required this.volunteerId,
    required this.fullName,
    required this.displayName,
    this.partySize = 1,
    this.avatarUrl,
    this.attendanceStatus,
    this.checkedIn = false,
    this.checkedInAt,
  });

  factory AttendanceVolunteer.fromJson(Map<String, dynamic> json) {
    final fullName = json['full_name'] as String? ?? '';
    return AttendanceVolunteer(
      participationId: json['participation_id'] as int,
      volunteerId: json['volunteer_id'] as int,
      fullName: fullName,
      displayName: json['display_name'] as String? ?? fullName,
      partySize: json['party_size'] as int? ?? 1,
      avatarUrl: json['avatar_url'] as String?,
      attendanceStatus: json['attendance_status'] as String?,
      checkedIn: json['checked_in'] as bool? ?? false,
      checkedInAt: json['checked_in_at'] as String?,
    );
  }
}

class CharityService {
  final ApiService _apiService;

  CharityService({required ApiService apiService}) : _apiService = apiService;

  /// GET /charity/dashboard
  Future<CharityDashboardData> getDashboard() async {
    final response = await _apiService.get(ApiEndpoints.charityDashboard);
    return CharityDashboardData.fromJson(response as Map<String, dynamic>);
  }

  /// GET /charity/opportunities — all opportunities (active + draft)
  Future<List<Map<String, dynamic>>> getCharityOpportunities() async {
    final response =
        await _apiService.get(ApiEndpoints.charityOpportunities);
    final data = response as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// GET /charity/profile
  Future<CharityProfile?> getProfile() async {
    final response = await _apiService.get(ApiEndpoints.charityProfile);
    if (response == null) return null;
    return CharityProfile.fromJson(response as Map<String, dynamic>);
  }

  /// POST /charity/profile — create a new charity profile
  Future<CharityProfile> createProfile({
    required String orgName,
    String? email,
    String? phone,
    String? website,
    String? mission,
    Map<String, String>? socialLinks,
  }) async {
    final body = <String, dynamic>{
      'org_name': orgName,
    };
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (website != null) body['website'] = website;
    if (mission != null) body['mission'] = mission;
    if (socialLinks != null) body['social_links'] = socialLinks;

    final response =
        await _apiService.put(ApiEndpoints.charityProfile, body: body);
    return CharityProfile.fromJson(response as Map<String, dynamic>);
  }

  /// PUT /charity/profile
  Future<CharityProfile> updateProfile({
    String? orgName,
    String? email,
    String? phone,
    String? website,
    String? mission,
    Map<String, String>? socialLinks,
  }) async {
    final body = <String, dynamic>{};
    if (orgName != null) body['org_name'] = orgName;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (website != null) body['website'] = website;
    if (mission != null) body['mission'] = mission;
    if (socialLinks != null) body['social_links'] = socialLinks;

    final response =
        await _apiService.put(ApiEndpoints.charityProfile, body: body);
    return CharityProfile.fromJson(response as Map<String, dynamic>);
  }

  /// POST /opportunities — create a new opportunity
  Future<Map<String, dynamic>> createOpportunity({
    required String title,
    required String address,
    required String startDatetime,
    int? volunteersNeeded,
    String? description,
    List<String>? category,
    String? endDatetime,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String status = 'active', // 'active' or 'draft'
    bool? kidsOk,
    bool? acceptsGroups,
    int? maxGroupSize,
    String? externalUrl,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'address': address,
      'start_datetime': startDatetime,
      'status': status,
    };
    if (volunteersNeeded != null) body['volunteers_needed'] = volunteersNeeded;
    if (description != null) body['description'] = description;
    if (category != null) body['category'] = category;
    if (endDatetime != null) body['end_datetime'] = endDatetime;
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (kidsOk != null) body['kids_ok'] = kidsOk;
    if (acceptsGroups != null) body['accepts_groups'] = acceptsGroups;
    if (maxGroupSize != null) body['max_group_size'] = maxGroupSize;
    if (externalUrl != null) body['external_url'] = externalUrl;

    final response =
        await _apiService.post(ApiEndpoints.opportunities, body: body);
    return Map<String, dynamic>.from(response as Map);
  }

  /// PUT /opportunities/:id — update an existing opportunity
  Future<Map<String, dynamic>> updateOpportunity({
    required int id,
    String? title,
    String? description,
    String? address,
    String? startDatetime,
    String? endDatetime,
    int? volunteersNeeded,
    List<String>? category,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? status,
    bool? kidsOk,
    bool? acceptsGroups,
    int? maxGroupSize,
    String? externalUrl,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (address != null) body['address'] = address;
    if (startDatetime != null) body['start_datetime'] = startDatetime;
    if (endDatetime != null) body['end_datetime'] = endDatetime;
    if (volunteersNeeded != null) body['volunteers_needed'] = volunteersNeeded;
    if (category != null) body['category'] = category;
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (status != null) body['status'] = status;
    if (kidsOk != null) body['kids_ok'] = kidsOk;
    if (acceptsGroups != null) body['accepts_groups'] = acceptsGroups;
    if (maxGroupSize != null) body['max_group_size'] = maxGroupSize;
    if (externalUrl != null) body['external_url'] = externalUrl;

    final response = await _apiService.put(
      ApiEndpoints.opportunityById(id),
      body: body,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  /// GET /opportunities/:id/volunteers
  Future<VolunteerAttendanceData> getVolunteers(int opportunityId) async {
    final response = await _apiService
        .get(ApiEndpoints.opportunityVolunteers(opportunityId));
    return VolunteerAttendanceData.fromJson(
        response as Map<String, dynamic>);
  }

  /// PUT /opportunities/:id/attendance
  Future<void> saveAttendance(
    int opportunityId,
    List<Map<String, dynamic>> attendance,
  ) async {
    await _apiService.put(
      ApiEndpoints.opportunityAttendance(opportunityId),
      body: {'attendance': attendance},
    );
  }

  /// GET /opportunities/:id/qr
  Future<Map<String, dynamic>> getQrToken(int opportunityId) async {
    final response =
        await _apiService.get(ApiEndpoints.opportunityQr(opportunityId));
    return Map<String, dynamic>.from(response as Map);
  }

  /// POST /media/upload — upload image for opportunity
  Future<String> uploadImage(String filePath) async {
    final response = await _apiService.multipartPost(
      ApiEndpoints.mediaUpload,
      filePath: filePath,
      fileField: 'file',
    );
    final data = response as Map<String, dynamic>;
    return data['url'] as String? ?? '';
  }

  /// Upload charity logo via /media/upload, then update profile with the URL
  Future<String> uploadLogo(String filePath) async {
    // First upload the image
    final imageUrl = await uploadImage(filePath);
    // Then update the charity profile with the new logo URL
    await _apiService.put(ApiEndpoints.charityProfile, body: {
      'logo_url': imageUrl,
    });
    return imageUrl;
  }

  // ─── Claim Flow ──────────────────────────────────────────────

  /// GET /charity/search-unclaimed?query= — Search unclaimed organizations.
  Future<List<Map<String, dynamic>>> searchUnclaimed(String query) async {
    final response = await _apiService.get(
      ApiEndpoints.charitySearchUnclaimed,
      queryParams: {'query': query},
    );
    final map = response as Map<String, dynamic>;
    final list = (map['data'] as List<dynamic>?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// POST /charity/claim — Claim an org. Returns claim response.
  Future<Map<String, dynamic>> claimListing(int charityId) async {
    final response = await _apiService.post(
      ApiEndpoints.charityClaim,
      body: {'charity_id': charityId},
    );
    return response as Map<String, dynamic>;
  }

  /// POST /charity/claim/confirm — Confirm claim with email token.
  Future<Map<String, dynamic>> confirmClaim(String token) async {
    final response = await _apiService.post(
      ApiEndpoints.charityClaimConfirm,
      body: {'token': token},
    );
    return response as Map<String, dynamic>;
  }
}
