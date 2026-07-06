import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/volunteer_service.dart';

class VolunteerProvider extends ChangeNotifier {
  final VolunteerService _volunteerService;

  ImpactData? _impactData;
  bool _isLoading = false;
  String? _errorMessage;

  VolunteerProvider({required VolunteerService volunteerService})
      : _volunteerService = volunteerService;

  ImpactData? get impactData => _impactData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic> get summary => _impactData?.summary ?? {};
  Map<String, dynamic> get impactScore => _impactData?.impactScore ?? {};
  List<Map<String, dynamic>> get monthlyHours =>
      _impactData?.monthlyHours ?? [];
  List<Map<String, dynamic>> get achievements =>
      _impactData?.achievements ?? [];

  double get totalHours =>
      (summary['total_hours'] as num?)?.toDouble() ?? 0;
  int get eventsDone => summary['events_done'] as int? ?? 0;
  int get communities => summary['communities'] as int? ?? 0;
  int get dayStreak => summary['day_streak'] as int? ?? 0;
  String get impactEquivalent =>
      summary['impact_equivalent'] as String? ?? '';

  /// Single call to GET /impact returns everything
  Future<void> fetchImpact() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _impactData = await _volunteerService.getImpact();
    } catch (e) {
      _errorMessage = _extractMessage(e);
    }

    _isLoading = false;
    notifyListeners();
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
