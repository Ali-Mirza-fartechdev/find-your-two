class OpportunityCharity {
  final int id;
  final String orgName;
  final String? logoUrl;
  final bool verified;

  const OpportunityCharity({
    required this.id,
    required this.orgName,
    this.logoUrl,
    this.verified = false,
  });

  factory OpportunityCharity.fromJson(Map<String, dynamic> json) {
    return OpportunityCharity(
      id: json['id'] as int,
      orgName: json['org_name'] as String,
      logoUrl: json['logo_url'] as String?,
      verified: json['verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'org_name': orgName,
        'logo_url': logoUrl,
        'verified': verified,
      };
}

class UserParticipation {
  final int id;
  final String status;
  final bool checkedIn;
  final int partySize;

  const UserParticipation({
    required this.id,
    required this.status,
    this.checkedIn = false,
    this.partySize = 1,
  });

  factory UserParticipation.fromJson(Map<String, dynamic> json) {
    return UserParticipation(
      id: json['id'] as int,
      status: json['status'] as String,
      checkedIn: json['checked_in'] as bool? ?? false,
      partySize: json['party_size'] as int? ?? 1,
    );
  }
}

class Opportunity {
  final int id;
  final String title;
  final String? description;
  final List<String> category;
  final String? imageUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? startDatetime;
  final String? endDatetime;
  final int? volunteersNeeded;
  final int volunteerCount;
  final bool? kidsOk;
  final bool acceptsGroups;
  final int? maxGroupSize;
  final String? externalUrl;
  final bool isSaved;
  final double? distanceKm;
  final String status;
  final OpportunityCharity? charity;
  final UserParticipation? userParticipation;
  final Map<String, dynamic>? eventStatistics;

  const Opportunity({
    required this.id,
    required this.title,
    this.description,
    this.category = const [],
    this.imageUrl,
    this.address,
    this.latitude,
    this.longitude,
    this.startDatetime,
    this.endDatetime,
    this.volunteersNeeded,
    this.volunteerCount = 0,
    this.kidsOk,
    this.acceptsGroups = false,
    this.maxGroupSize,
    this.externalUrl,
    this.isSaved = false,
    this.distanceKm,
    this.status = 'active',
    this.charity,
    this.userParticipation,
    this.eventStatistics,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: _parseStringList(json['category']),
      imageUrl: json['image_url'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      startDatetime: json['start_datetime'] as String?,
      endDatetime: json['end_datetime'] as String?,
      volunteersNeeded: json['volunteers_needed'] as int?,
      volunteerCount: json['volunteer_count'] as int? ?? 0,
      kidsOk: json['kids_ok'] as bool?,
      acceptsGroups: json['accepts_groups'] as bool? ?? false,
      maxGroupSize: json['max_group_size'] as int?,
      externalUrl: json['external_url'] as String?,
      isSaved: json['is_saved'] as bool? ?? false,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'active',
      charity: json['charity'] != null
          ? OpportunityCharity.fromJson(json['charity'] as Map<String, dynamic>)
          : null,
      userParticipation: json['user_participation'] != null
          ? UserParticipation.fromJson(
              json['user_participation'] as Map<String, dynamic>)
          : null,
      eventStatistics: json['event_statistics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'image_url': imageUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'start_datetime': startDatetime,
      'end_datetime': endDatetime,
      'volunteers_needed': volunteersNeeded,
      'volunteer_count': volunteerCount,
      'kids_ok': kidsOk,
      'accepts_groups': acceptsGroups,
      'max_group_size': maxGroupSize,
      'external_url': externalUrl,
      'is_saved': isSaved,
      'distance_km': distanceKm,
      'status': status,
      'charity': charity?.toJson(),
    };
  }

  bool get isActive => status == 'active';
  bool get isEnrolled => userParticipation != null;
  bool get isCheckedIn => userParticipation?.checkedIn ?? false;
  bool get isUncapped => volunteersNeeded == null;
  bool get isFull =>
      !isUncapped && volunteerCount >= volunteersNeeded!;
  int get spotsLeft =>
      isUncapped ? -1 : (volunteersNeeded! > volunteerCount ? volunteersNeeded! - volunteerCount : 0);
  double get progress =>
      isUncapped ? 0 : (volunteersNeeded! > 0 ? volunteerCount / volunteersNeeded! : 0);
  String get charityName => charity?.orgName ?? '';
  bool get isExternal => externalUrl != null && externalUrl!.isNotEmpty;
  bool get hasKidsBadge => kidsOk != null;

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
