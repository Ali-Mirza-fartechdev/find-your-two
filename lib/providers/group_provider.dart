import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../services/api_service.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _groupService;

  List<Group> _groups = [];
  Group? _selectedGroup;
  bool _isLoading = false;
  String? _errorMessage;

  GroupProvider({required GroupService groupService})
      : _groupService = groupService;

  List<Group> get groups => _groups;
  Group? get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groups = await _groupService.getGroups();
    } catch (e) {
      _errorMessage = _extractMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchGroupDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedGroup = await _groupService.getGroupDetail(id);
    } catch (e) {
      _errorMessage = _extractMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createGroup({required String name}) async {
    _errorMessage = null;
    try {
      final group = await _groupService.createGroup(name: name);
      _groups = [group, ..._groups];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<String?> inviteMember(int groupId, {required String email}) async {
    _errorMessage = null;
    try {
      final token = await _groupService.inviteMember(groupId, email: email);
      // Refresh group detail to show new invite
      await fetchGroupDetail(groupId);
      return token;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> joinGroup({required String token}) async {
    _errorMessage = null;
    try {
      await _groupService.joinGroup(token: token);
      await fetchGroups();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveGroup(int groupId) async {
    _errorMessage = null;
    try {
      await _groupService.leaveGroup(groupId);
      _groups.removeWhere((g) => g.id == groupId);
      _selectedGroup = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeMember(int groupId, int memberId) async {
    _errorMessage = null;
    try {
      await _groupService.removeMember(groupId, memberId);
      // Refresh group detail to update members list
      await fetchGroupDetail(groupId);
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _extractMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is NetworkException) return error.message;
    final msg = error.toString();
    final match = RegExp(r'ApiException\(\d+\): (.+)').firstMatch(msg);
    if (match != null) return match.group(1)!;
    if (msg.contains('type') || msg.contains('Exception') ||
        msg.contains('null') || msg.contains('cast') ||
        msg.contains('Error') || msg.length > 100) {
      return 'Something went wrong. Please try again.';
    }
    return msg;
  }
}
