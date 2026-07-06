class Referral {
  final int id;
  final int referrerId;
  final int referredId;
  final String? referredName;
  final DateTime timestamp;

  const Referral({
    required this.id,
    required this.referrerId,
    required this.referredId,
    this.referredName,
    required this.timestamp,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as int,
      referrerId: json['referrer_id'] as int,
      referredId: json['referred_id'] as int,
      referredName: json['referred_name'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrer_id': referrerId,
      'referred_id': referredId,
      'referred_name': referredName,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
