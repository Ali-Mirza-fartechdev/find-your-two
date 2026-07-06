import 'package:flutter/foundation.dart';
import '../models/opportunity.dart';
import '../services/api_service.dart';
import '../services/opportunity_service.dart';

class OpportunityProvider extends ChangeNotifier {
  final OpportunityService _opportunityService;

  List<Opportunity> _opportunities = [];
  List<Map<String, dynamic>> _myOpportunities = [];
  List<Opportunity> _savedOpportunities = [];
  Opportunity? _selectedOpportunity;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _total = 0;
  bool _hasMore = true;

  // Tracks the active request so stale responses are discarded
  int _fetchId = 0;

  // Tracks current filter params so we can detect changes
  String? _activeCategory;
  String? _activeSearch;

  // Multi-select filter state
  List<String>? _activeCategories;
  bool? _activeKidsOk;
  bool? _activeAcceptsGroups;
  List<String>? _activeDaysOfWeek;
  List<String>? _activeTimesOfDay;

  // User location for nearby fetch
  double? _userLatitude;
  double? _userLongitude;
  String? _userAddress;

  OpportunityProvider({required OpportunityService opportunityService})
      : _opportunityService = opportunityService;

  List<Opportunity> get opportunities => _opportunities;
  List<Map<String, dynamic>> get myOpportunities => _myOpportunities;
  List<Opportunity> get savedOpportunities => _savedOpportunities;
  Opportunity? get selectedOpportunity => _selectedOpportunity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  int get total => _total;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  String? get userAddress => _userAddress;
  bool get hasLocation => _userLatitude != null && _userLongitude != null;

  void setUserLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _userAddress = address;
    notifyListeners();
  }

  Future<void> fetchOpportunities({
    bool refresh = false,
    String? category,
    List<String>? categories,
    String? search,
    bool? kidsOk,
    bool? acceptsGroups,
    List<String>? daysOfWeek,
    List<String>? timesOfDay,
  }) async {
    final paramsChanged = category != _activeCategory ||
        search != _activeSearch ||
        categories.toString() != _activeCategories.toString() ||
        kidsOk != _activeKidsOk ||
        acceptsGroups != _activeAcceptsGroups ||
        daysOfWeek.toString() != _activeDaysOfWeek.toString() ||
        timesOfDay.toString() != _activeTimesOfDay.toString();
    if (paramsChanged) refresh = true;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _activeCategory = category;
      _activeSearch = search;
      _activeCategories = categories;
      _activeKidsOk = kidsOk;
      _activeAcceptsGroups = acceptsGroups;
      _activeDaysOfWeek = daysOfWeek;
      _activeTimesOfDay = timesOfDay;
      _opportunities = [];
      _total = 0;
    }

    // For non-refresh pagination: skip if already loading or nothing more
    if (!refresh && (_isLoading || !_hasMore)) return;

    _isLoading = true;
    _errorMessage = null;
    final thisRequest = ++_fetchId;
    notifyListeners();

    final hasFilters = category != null ||
        (categories != null && categories.isNotEmpty) ||
        search != null ||
        kidsOk != null ||
        acceptsGroups != null ||
        (daysOfWeek != null && daysOfWeek.isNotEmpty) ||
        (timesOfDay != null && timesOfDay.isNotEmpty);

    try {
      // Use nearby endpoint if location is set and no filters applied
      if (hasLocation && !hasFilters && _currentPage == 1) {
        final nearbyResults = await _opportunityService.getNearbyOpportunities(
          latitude: _userLatitude!,
          longitude: _userLongitude!,
          radius: 50, // 50km radius
        );

        if (thisRequest != _fetchId) return;

        _opportunities = nearbyResults;
        _total = nearbyResults.length;
        _hasMore = false; // Nearby returns all at once
      } else {
        final result = await _opportunityService.getOpportunities(
          page: _currentPage,
          category: category,
          categories: categories,
          search: search,
          kidsOk: kidsOk,
          acceptsGroups: acceptsGroups,
          daysOfWeek: daysOfWeek,
          timesOfDay: timesOfDay,
        );

        if (thisRequest != _fetchId) return;

        if (refresh) {
          _opportunities = result.data;
        } else {
          _opportunities = [..._opportunities, ...result.data];
        }

        _total = result.total;
        _hasMore = _opportunities.length < _total;
        _currentPage++;
      }
    } catch (e) {
      if (thisRequest != _fetchId) return;
      _errorMessage = _extractMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchOpportunityById(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedOpportunity =
          await _opportunityService.getOpportunityById(id);
    } catch (e) {
      _errorMessage = _extractMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyOpportunities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _opportunityService.getMyOpportunities();
      _myOpportunities = result.data;
    } catch (e) {
      _errorMessage = _extractMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> enrollInOpportunity(
    int id, {
    required String fullName,
    required String phoneNumber,
    required String email,
    int partySize = 1,
    int? groupId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _opportunityService.enrollInOpportunity(
        id,
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        partySize: partySize,
        groupId: groupId,
      );
    } catch (e) {
      _errorMessage = _extractMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> withdrawFromOpportunity(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _opportunityService.withdrawFromOpportunity(id);
      _myOpportunities.removeWhere((o) {
        final opp = o['opportunity'] as Map<String, dynamic>?;
        return opp?['id'] == id;
      });
    } catch (e) {
      _errorMessage = _extractMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Saved Opportunities ──────────────────────────────────────

  Future<void> fetchSavedOpportunities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _savedOpportunities = await _opportunityService.getSavedOpportunities();
    } catch (e) {
      _errorMessage = _extractMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveOpportunity(int id) async {
    _errorMessage = null;
    try {
      await _opportunityService.saveOpportunity(id);
      // Update is_saved in local lists
      _updateSavedState(id, true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> unsaveOpportunity(int id) async {
    _errorMessage = null;
    try {
      await _opportunityService.unsaveOpportunity(id);
      _updateSavedState(id, false);
      _savedOpportunities.removeWhere((o) => o.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  void _updateSavedState(int id, bool saved) {
    _opportunities = _opportunities.map((o) {
      if (o.id == id) {
        return Opportunity.fromJson({...o.toJson(), 'is_saved': saved});
      }
      return o;
    }).toList();
    if (_selectedOpportunity?.id == id) {
      _selectedOpportunity = Opportunity.fromJson(
          {..._selectedOpportunity!.toJson(), 'is_saved': saved});
    }
  }

  // ─── Track Click (External Signup) ──────────────────────────

  Future<String?> trackClick(int id) async {
    _errorMessage = null;
    try {
      return await _opportunityService.trackClick(id);
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return null;
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
