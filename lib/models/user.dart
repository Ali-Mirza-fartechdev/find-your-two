class User {
  final int id;
  final String name;
  final String email;
  final String mode;
  final String? avatarUrl;
  final String? location;
  final List<String> skills;
  final List<String> interests;
  final List<String> availability;
  final double? latitude;
  final double? longitude;
  final String? memberSince;
  final String? communityTitle;
  final bool emailVerified;
  final bool? kidsOkPreferred;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.mode,
    this.avatarUrl,
    this.location,
    this.skills = const [],
    this.interests = const [],
    this.availability = const [],
    this.latitude,
    this.longitude,
    this.memberSince,
    this.communityTitle,
    this.emailVerified = false,
    this.kidsOkPreferred,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name'] as String,
      email: json['email'] as String,
      mode: json['mode'] as String,
      avatarUrl: json['avatar_url'] as String?,
      location: json['location'] as String?,
      skills: _parseStringList(json['skills']),
      interests: _parseStringList(json['interests']),
      availability: _parseStringList(json['availability']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      memberSince: json['member_since'] as String?,
      communityTitle: json['community_title'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      kidsOkPreferred: json['kids_ok_preferred'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mode': mode,
      'avatar_url': avatarUrl,
      'location': location,
      'skills': skills,
      'interests': interests,
      'availability': availability,
      'latitude': latitude,
      'longitude': longitude,
      'member_since': memberSince,
      'community_title': communityTitle,
      'email_verified': emailVerified,
      'kids_ok_preferred': kidsOkPreferred,
    };
  }

  bool get isVolunteer => mode == 'volunteer';
  bool get isCharity => mode == 'charity';

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  bool get hasLocation => latitude != null && longitude != null && latitude != 0 && longitude != 0;

  User copyWith({
    String? name,
    String? mode,
    String? avatarUrl,
    String? location,
    List<String>? skills,
    List<String>? interests,
    List<String>? availability,
    double? latitude,
    double? longitude,
    String? memberSince,
    String? communityTitle,
    bool? emailVerified,
    bool? kidsOkPreferred,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      mode: mode ?? this.mode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      availability: availability ?? this.availability,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      memberSince: memberSince ?? this.memberSince,
      communityTitle: communityTitle ?? this.communityTitle,
      emailVerified: emailVerified ?? this.emailVerified,
      kidsOkPreferred: kidsOkPreferred ?? this.kidsOkPreferred,
    );
  }
}
