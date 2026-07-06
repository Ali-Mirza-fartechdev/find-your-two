import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/profile_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final ProfileService? _profileService;
  final DeviceService? _deviceService;

  AuthState _state = AuthState.initial;
  User? _user;
  String? _errorMessage;
  String? _fcmToken;

  AuthProvider({
    required AuthService authService,
    ProfileService? profileService,
    DeviceService? deviceService,
  })  : _authService = authService,
        _profileService = profileService,
        _deviceService = deviceService;

  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> checkAuthStatus() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final hasToken = await _authService.isLoggedIn();
      if (!hasToken) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      _user = await _authService.fetchMe();
      _state = AuthState.authenticated;
    } catch (_) {
      await _authService.logout();
      _user = null;
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email: email, password: password);
      _state = AuthState.authenticated;
      _registerFcmToken();
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _state = AuthState.error;
    }
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
    String? referralCode,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        role: role,
        referralCode: referralCode,
      );
      _state = AuthState.authenticated;
      _registerFcmToken();
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _state = AuthState.error;
    }
    notifyListeners();
  }

  // ─── Social Login ──────────────────────────────────────────────

  Future<void> loginWithGoogle() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.loginWithGoogle();
      _state = AuthState.authenticated;
      _registerFcmToken();
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _state = AuthState.error;
    }
    notifyListeners();
  }

  Future<void> loginWithApple() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.loginWithApple();
      _state = AuthState.authenticated;
      _registerFcmToken();
    } catch (e) {
      _errorMessage = _extractMessage(e);
      _state = AuthState.error;
    }
    notifyListeners();
  }

  Future<void> forgotPassword({required String email}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(email: email);
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Verify OTP → returns reset_token on success, throws on failure
  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _errorMessage = null;
    try {
      return await _authService.verifyOtp(email: email, otp: otp);
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Reset password using the reset_token from verifyOtp
  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
    required String resetToken,
  }) async {
    _errorMessage = null;
    try {
      await _authService.resetPassword(
        email: email,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
        resetToken: resetToken,
      );
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> switchMode({required String mode}) async {
    try {
      await _authService.switchMode(mode: mode);
      if (_user != null) {
        _user = _user!.copyWith(mode: mode);
      }
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
    }
  }

  // ─── Profile Management ──────────────────────────────────────────

  Future<void> fetchProfile() async {
    if (_profileService == null) return;
    try {
      _user = await _profileService.getProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? location,
    List<String>? skills,
    List<String>? interests,
    List<String>? availability,
    double? latitude,
    double? longitude,
    bool? kidsOkPreferred,
  }) async {
    if (_profileService == null) return false;
    _errorMessage = null;
    try {
      _user = await _profileService.updateProfile(
        name: name,
        location: location,
        latitude: latitude,
        longitude: longitude,
        skills: skills,
        interests: interests,
        availability: availability,
        kidsOkPreferred: kidsOkPreferred,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    if (_profileService == null) return false;
    _errorMessage = null;
    try {
      final avatarUrl = await _profileService.uploadAvatar(filePath);
      _user = _user?.copyWith(avatarUrl: avatarUrl);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _errorMessage = null;
    try {
      await _unregisterFcmToken();
      await _authService.deleteAccount();
      _user = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _unregisterFcmToken();
    await _authService.logout();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // ─── FCM Token Management ─────────────────────────────────────

  Future<void> _registerFcmToken() async {
    if (_deviceService == null) return;
    try {
      // Request notification permission (iOS)
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _fcmToken = token;
        await _deviceService.registerDevice(fcmToken: token);
      }
    } catch (_) {
      // Expected to fail on iOS simulator (no APNS)
    }
  }

  Future<void> _unregisterFcmToken() async {
    if (_deviceService == null || _fcmToken == null) return;
    try {
      await _deviceService.unregisterDevice(fcmToken: _fcmToken!);
      _fcmToken = null;
    } catch (_) {
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
    // Never show raw technical errors to users
    if (msg.contains('type') || msg.contains('Exception') ||
        msg.contains('null') || msg.contains('cast') ||
        msg.contains('Error') || msg.length > 100) {
      return 'Something went wrong. Please try again.';
    }
    return msg;
  }
}
