import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/charity_service.dart';

class CharityProvider extends ChangeNotifier {
  final CharityService _charityService;

  CharityProvider({required CharityService charityService})
      : _charityService = charityService;

  // ─── State ─────────────────────────────────────────────────────────
  CharityDashboardData? _dashboard;
  CharityProfile? _profile;
  VolunteerAttendanceData? _attendanceData;
  Map<String, dynamic>? _qrData;
  List<Map<String, dynamic>>? _charityOpportunities;
  bool _isLoading = false;
  String? _errorMessage;
  String? _dashboardError; // Separate error for dashboard fetch
  bool _noCharityProfile = false;

  // Claim flow state
  List<Map<String, dynamic>> _unclaimedResults = [];
  bool _isClaimLoading = false;
  String? _claimError;

  // ─── Getters ───────────────────────────────────────────────────────
  CharityDashboardData? get dashboard => _dashboard;
  CharityProfile? get profile => _profile;
  VolunteerAttendanceData? get attendanceData => _attendanceData;
  Map<String, dynamic>? get qrData => _qrData;
  List<Map<String, dynamic>>? get charityOpportunities => _charityOpportunities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get dashboardError => _dashboardError;
  bool get noCharityProfile => _noCharityProfile;
  List<Map<String, dynamic>> get unclaimedResults => _unclaimedResults;
  bool get isClaimLoading => _isClaimLoading;
  String? get claimError => _claimError;

  // ─── Dashboard ─────────────────────────────────────────────────────
  Future<void> fetchDashboard() async {
    final isFirstLoad = _dashboard == null;
    if (isFirstLoad) {
      _isLoading = true;
      notifyListeners();
    }
    _dashboardError = null;
    _noCharityProfile = false;

    try {
      _dashboard = await _charityService.getDashboard();
    } catch (e) {
      if (e is ApiException && e.statusCode == 403) {
        _noCharityProfile = true;
      }
      _dashboardError = _extractMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Charity Opportunities ──────────────────────────────────────────
  Future<void> fetchCharityOpportunities() async {
    try {
      _charityOpportunities = await _charityService.getCharityOpportunities();
    } catch (_) {
      // Don't set _errorMessage — this runs in parallel with fetchDashboard
      // and would cause the error screen to flash before dashboard loads
    }
    notifyListeners();
  }

  // ─── Profile ───────────────────────────────────────────────────────
  Future<void> fetchProfile() async {
    final isFirstLoad = _profile == null;
    if (isFirstLoad) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      _profile = await _charityService.getProfile();
    } catch (e) {
      _errorMessage = _extractMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createProfile({
    required String orgName,
    String? email,
    String? phone,
    String? website,
    String? mission,
    Map<String, String>? socialLinks,
  }) async {
    _errorMessage = null;
    try {
      _profile = await _charityService.createProfile(
        orgName: orgName,
        email: email,
        phone: phone,
        website: website,
        mission: mission,
        socialLinks: socialLinks,
      );
      _noCharityProfile = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? orgName,
    String? email,
    String? phone,
    String? website,
    String? mission,
    Map<String, String>? socialLinks,
  }) async {
    _errorMessage = null;
    try {
      _profile = await _charityService.updateProfile(
        orgName: orgName,
        email: email,
        phone: phone,
        website: website,
        mission: mission,
        socialLinks: socialLinks,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadLogo(String filePath) async {
    _errorMessage = null;
    try {
      final url = await _charityService.uploadLogo(filePath);
      // Update local profile with new logo
      if (_profile != null) {
        _profile = CharityProfile(
          id: _profile!.id,
          orgName: _profile!.orgName,
          email: _profile!.email,
          phone: _profile!.phone,
          website: _profile!.website,
          mission: _profile!.mission,
          logoUrl: url,
          verified: _profile!.verified,
          socialLinks: _profile!.socialLinks,
        );
      }
      notifyListeners();
      return url;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return null;
    }
  }

  // ─── Create Opportunity ────────────────────────────────────────────
  Future<Map<String, dynamic>?> createOpportunity({
    required String title,
    required String address,
    required String startDatetime,
    int? volunteersNeeded,
    String? description,
    List<String>? category,
    String? endDatetime,
    String? imagePath,
    double? latitude,
    double? longitude,
    String status = 'active',
    bool? kidsOk,
    bool? acceptsGroups,
    int? maxGroupSize,
    String? externalUrl,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      String? imageUrl;
      if (imagePath != null) {
        imageUrl = await _charityService.uploadImage(imagePath);
      }

      final result = await _charityService.createOpportunity(
        title: title,
        address: address,
        startDatetime: startDatetime,
        volunteersNeeded: volunteersNeeded,
        description: description,
        category: category,
        endDatetime: endDatetime,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        status: status,
        kidsOk: kidsOk,
        acceptsGroups: acceptsGroups,
        maxGroupSize: maxGroupSize,
        externalUrl: externalUrl,
      );
      return result;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return null;
    }
  }

  // ─── Update Opportunity ───────────────────────────────────────────
  Future<Map<String, dynamic>?> updateOpportunity({
    required int id,
    String? title,
    String? description,
    String? address,
    String? startDatetime,
    String? endDatetime,
    int? volunteersNeeded,
    List<String>? category,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? status,
    bool? kidsOk,
    bool? acceptsGroups,
    int? maxGroupSize,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      String? imageUrl;
      if (imagePath != null) {
        imageUrl = await _charityService.uploadImage(imagePath);
      }

      final result = await _charityService.updateOpportunity(
        id: id,
        title: title,
        description: description,
        address: address,
        startDatetime: startDatetime,
        endDatetime: endDatetime,
        volunteersNeeded: volunteersNeeded,
        category: category,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        status: status,
        kidsOk: kidsOk,
        acceptsGroups: acceptsGroups,
        maxGroupSize: maxGroupSize,
      );
      return result;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return null;
    }
  }

  // ─── Volunteers & Attendance ───────────────────────────────────────
  Future<void> fetchVolunteers(int opportunityId) async {
    _attendanceData = null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _attendanceData = await _charityService.getVolunteers(opportunityId);
    } catch (e) {
      _errorMessage = _extractMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveAttendance(
    int opportunityId,
    List<Map<String, dynamic>> attendance,
  ) async {
    _errorMessage = null;
    try {
      await _charityService.saveAttendance(opportunityId, attendance);
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ─── QR Code ───────────────────────────────────────────────────────
  Future<void> fetchQrToken(int opportunityId) async {
    _errorMessage = null;
    try {
      _qrData = await _charityService.getQrToken(opportunityId);
      notifyListeners();
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
    }
  }

  // ─── Claim Flow ───────────────────────────────────────────────────
  Future<void> searchUnclaimed(String query) async {
    _isClaimLoading = true;
    _claimError = null;
    notifyListeners();

    try {
      _unclaimedResults = await _charityService.searchUnclaimed(query);
    } catch (e) {
      _claimError = _extractMessage(e);
    }
    _isClaimLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> claimListing(int charityId) async {
    _claimError = null;
    try {
      final result = await _charityService.claimListing(charityId);
      return result;
    } catch (e) {
      _claimError = _extractMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirmClaim(String token) async {
    _claimError = null;
    try {
      await _charityService.confirmClaim(token);
      _noCharityProfile = false;
      notifyListeners();
      return true;
    } catch (e) {
      _claimError = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  void clearClaimError() {
    _claimError = null;
    notifyListeners();
  }

  // ─── Helpers ───────────────────────────────────────────────────────
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
