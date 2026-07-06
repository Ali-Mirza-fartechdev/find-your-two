import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../config/api_endpoints.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );

    final token = response['token'] as String;
    await _storageService.saveToken(token);

    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    await _storageService.saveUserData(jsonEncode(user.toJson()));

    return user;
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
    String? referralCode,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
      'role': role,
    };

    if (referralCode != null) {
      body['referral_code'] = referralCode;
    }

    final response = await _apiService.post(
      ApiEndpoints.register,
      body: body,
      requiresAuth: false,
    );

    final token = response['token'] as String;
    await _storageService.saveToken(token);

    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    await _storageService.saveUserData(jsonEncode(user.toJson()));

    return user;
  }

  Future<User> fetchMe() async {
    final response = await _apiService.get(ApiEndpoints.me);
    final user = User.fromJson(response as Map<String, dynamic>);
    await _storageService.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  Future<void> forgotPassword({required String email}) async {
    await _apiService.post(
      ApiEndpoints.forgotPassword,
      body: {'email': email},
      requiresAuth: false,
    );
  }

  /// Verify OTP → returns reset_token
  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.verifyOtp,
      body: {'email': email, 'otp': otp},
      requiresAuth: false,
    );
    return response['reset_token'] as String;
  }

  /// Reset password using reset_token
  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
    required String resetToken,
  }) async {
    await _apiService.post(
      ApiEndpoints.resetPassword,
      body: {
        'email': email,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
        'reset_token': resetToken,
      },
      requiresAuth: false,
    );
  }

  // ─── Social Login (Firebase OAuth) ──────────────────────────────

  /// Send Firebase ID token to backend, get JWT + User
  Future<User> _loginWithFirebaseToken(String firebaseIdToken, {String mode = 'volunteer'}) async {
    final response = await _apiService.post(
      ApiEndpoints.login,
      body: {
        'firebase_token': firebaseIdToken,
        'mode': mode,
      },
      requiresAuth: false,
    );

    final token = response['token'] as String;
    await _storageService.saveToken(token);

    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    await _storageService.saveUserData(jsonEncode(user.toJson()));

    return user;
  }

  /// Google Sign-In → Firebase Auth → Backend JWT
  Future<User> loginWithGoogle({String mode = 'volunteer'}) async {
    final gsi = GoogleSignIn.instance;
    await gsi.initialize();

    final googleUser = await gsi.authenticate();
    final googleAuth = googleUser.authentication;

    final credential = fb.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final fbUser = await fb.FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await fbUser.user?.getIdToken();
    if (idToken == null) throw Exception('Failed to get Firebase token');

    return _loginWithFirebaseToken(idToken, mode: mode);
  }

  /// Apple Sign-In → Firebase Auth → Backend JWT
  Future<User> loginWithApple({String mode = 'volunteer'}) async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = fb.OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final fbUser = await fb.FirebaseAuth.instance.signInWithCredential(oauthCredential);
    final idToken = await fbUser.user?.getIdToken();
    if (idToken == null) throw Exception('Failed to get Firebase token');

    return _loginWithFirebaseToken(idToken, mode: mode);
  }

  Future<void> switchMode({required String mode}) async {
    await _apiService.put(
      ApiEndpoints.switchMode,
      body: {'mode': mode},
    );
  }

  Future<void> deleteAccount() async {
    await _apiService.delete(ApiEndpoints.deleteAccount);
    await _storageService.clearAll();
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

  Future<User?> getCurrentUser() async {
    final userData = await _storageService.getUserData();
    if (userData == null) return null;

    return User.fromJson(jsonDecode(userData) as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null;
  }
}
