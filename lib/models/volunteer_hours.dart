class VolunteerHours {
  final int id;
  final int volunteerId;
  final int opportunityId;
  final String? opportunityTitle;
  final double hours;
  final DateTime date;

  const VolunteerHours({
    required this.id,
    required this.volunteerId,
    required this.opportunityId,
    this.opportunityTitle,
    required this.hours,
    required this.date,
  });

  factory VolunteerHours.fromJson(Map<String, dynamic> json) {
    return VolunteerHours(
      id: json['id'] as int,
      volunteerId: json['volunteer_id'] as int,
      opportunityId: json['opportunity_id'] as int,
      opportunityTitle: json['opportunity_title'] as String?,
      hours: (json['hours'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'volunteer_id': volunteerId,
      'opportunity_id': opportunityId,
      'opportunity_title': opportunityTitle,
      'hours': hours,
      'date': date.toIso8601String(),
    };
  }
}
