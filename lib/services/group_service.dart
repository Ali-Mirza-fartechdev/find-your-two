import '../config/api_endpoints.dart';
import '../models/group.dart';
import 'api_service.dart';

class GroupService {
  final ApiService _apiService;

  GroupService({required ApiService apiService}) : _apiService = apiService;

  /// POST /groups — Create a new group.
  Future<Group> createGroup({required String name}) async {
    final response = await _apiService.post(
      ApiEndpoints.groups,
      body: {'name': name},
    );
    return Group.fromJson(response as Map<String, dynamic>);
  }

  /// GET /groups — List my groups.
  Future<List<Group>> getGroups() async {
    final response = await _apiService.get(ApiEndpoints.groups);
    final map = response as Map<String, dynamic>;
    final list = (map['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => Group.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /groups/:id — Group detail with members.
  Future<Group> getGroupDetail(int id) async {
    final response = await _apiService.get(ApiEndpoints.groupById(id));
    return Group.fromJson(response as Map<String, dynamic>);
  }

  /// POST /groups/:id/invite — Invite by email.
  /// Returns the invite token.
  Future<String> inviteMember(int groupId, {required String email}) async {
    final response = await _apiService.post(
      ApiEndpoints.groupInvite(groupId),
      body: {'email': email},
    );
    final map = response as Map<String, dynamic>;
    return map['invite_token'] as String? ?? '';
  }

  /// POST /groups/join — Join a group via invite token.
  /// Returns the joined group info.
  Future<Map<String, dynamic>> joinGroup({required String token}) async {
    final response = await _apiService.post(
      ApiEndpoints.groupJoin,
      body: {'token': token},
    );
    return response as Map<String, dynamic>;
  }

  /// POST /groups/:id/leave — Leave a group.
  Future<void> leaveGroup(int groupId) async {
    await _apiService.post(ApiEndpoints.groupLeave(groupId));
  }

  /// DELETE /groups/:id/members/:memberId — Remove a member.
  /// memberId is the membership record ID from the members array, NOT the user ID.
  Future<void> removeMember(int groupId, int memberId) async {
    await _apiService.delete(ApiEndpoints.groupRemoveMember(groupId, memberId));
  }
}
