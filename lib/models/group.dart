class GroupMember {
  final int id; // membership record ID, NOT user ID
  final String? email;
  final String? name; // null for pending invites
  final String status; // 'invited', 'accepted', 'removed'
  final String? invitedAt;
  final String? joinedAt;

  const GroupMember({
    required this.id,
    this.email,
    this.name,
    required this.status,
    this.invitedAt,
    this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as int,
      email: json['email'] as String?,
      name: json['name'] as String?,
      status: json['status'] as String? ?? 'invited',
      invitedAt: json['invited_at'] as String?,
      joinedAt: json['joined_at'] as String?,
    );
  }

  bool get isAccepted => status == 'accepted';
  bool get isInvited => status == 'invited';
}

class Group {
  final int id;
  final String name;
  final bool isOwner;
  final int memberCount;
  final List<GroupMember> members;

  const Group({
    required this.id,
    required this.name,
    this.isOwner = false,
    this.memberCount = 0,
    this.members = const [],
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      name: json['name'] as String,
      isOwner: json['is_owner'] as bool? ?? false,
      memberCount: json['member_count'] as int? ?? 0,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
