import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/checkin_service.dart';

class CheckinProvider extends ChangeNotifier {
  final CheckinService _checkinService;

  CheckinResult? _result;
  bool _isLoading = false;
  String? _errorMessage;

  CheckinProvider({required CheckinService checkinService})
      : _checkinService = checkinService;

  CheckinResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> checkinViaQr(int opportunityId, String qrToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _checkinService.checkinViaQr(opportunityId, qrToken);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkinViaGps(
    int opportunityId, {
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _checkinService.checkinViaGps(
        opportunityId,
        latitude: latitude,
        longitude: longitude,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchCheckinStatus(int opportunityId) async {
    try {
      _result = await _checkinService.getCheckinStatus(opportunityId);
      notifyListeners();
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
    }
  }

  void clearState() {
    _result = null;
    _errorMessage = null;
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
