import 'dart:convert';
import '../config/api_endpoints.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ProfileService {
  final ApiService _apiService;
  final StorageService _storageService;

  ProfileService({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  Future<User> getProfile() async {
    final response = await _apiService.get(ApiEndpoints.profile);
    final user = User.fromJson(response as Map<String, dynamic>);
    await _storageService.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  Future<User> updateProfile({
    String? name,
    String? location,
    List<String>? skills,
    List<String>? interests,
    List<String>? availability,
    double? latitude,
    double? longitude,
    bool? kidsOkPreferred,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (location != null) body['location'] = location;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (skills != null) body['skills'] = skills;
    if (interests != null) body['interests'] = interests;
    if (availability != null) body['availability'] = availability;
    if (kidsOkPreferred != null) body['kids_ok_preferred'] = kidsOkPreferred;

    final response = await _apiService.put(
      ApiEndpoints.profile,
      body: body,
    );

    final user = User.fromJson(response as Map<String, dynamic>);
    await _storageService.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  /// Upload avatar image. Returns the new avatar URL.
  Future<String> uploadAvatar(String filePath) async {
    final response = await _apiService.multipartPost(
      ApiEndpoints.profileAvatar,
      filePath: filePath,
      fileField: 'file',
    );
    return (response as Map<String, dynamic>)['avatar_url'] as String;
  }
}
