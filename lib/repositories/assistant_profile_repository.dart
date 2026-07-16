import 'package:event_planner/models/user_profile.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:flutter/foundation.dart';

class AssistantProfileRepositoryException implements Exception {
  final String message;

  AssistantProfileRepositoryException(this.message);

  @override
  String toString() => message;
}

class AssistantProfileRepository {
  static final ValueNotifier<UserProfile?> profile =
      ValueNotifier<UserProfile?>(null);

  static bool _loadedOnce = false;
  static Future<UserProfile>? _runningRefresh;

  static UserProfile? get cachedProfile => profile.value;

  static bool get hasCache => _loadedOnce && profile.value != null;

  static Future<UserProfile> loadProfile({bool forceRefresh = false}) async {
    final cached = profile.value;
    if (!forceRefresh && cached != null) return cached;

    final runningRefresh = _runningRefresh;
    if (runningRefresh != null) return runningRefresh;

    final request = _fetchProfile();
    _runningRefresh = request;

    try {
      return await request;
    } finally {
      _runningRefresh = null;
    }
  }

  static Future<void> refreshInBackground() async {
    try {
      await loadProfile(forceRefresh: true);
    } catch (e) {
      debugPrint('Assistant profile background refresh error: $e');
    }
  }

  static Future<UserProfile> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final result = await ApiService.updateAssistantProfile(
      name: name,
      email: email,
      phone: phone,
    );

    if (result['success'] == false) {
      throw AssistantProfileRepositoryException(
        _apiMessage(result, 'Failed to update profile'),
      );
    }

    final updatedProfile = UserProfile.fromApiResponse(result);
    profile.value = updatedProfile;
    _loadedOnce = true;
    return updatedProfile;
  }

  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await ApiService.updateAssistantPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (result['success'] == false) {
      throw AssistantProfileRepositoryException(
        _apiMessage(result, 'Failed to update password'),
      );
    }
  }

  static void clear() {
    profile.value = null;
    _loadedOnce = false;
    _runningRefresh = null;
  }

  static Future<UserProfile> _fetchProfile() async {
    final result = await ApiService.getAssistantProfile();

    if (result['success'] == false) {
      throw AssistantProfileRepositoryException(
        _apiMessage(result, 'Failed to load profile'),
      );
    }

    final loadedProfile = UserProfile.fromApiResponse(result);
    profile.value = loadedProfile;
    _loadedOnce = true;
    return loadedProfile;
  }

  static String _apiMessage(Map<String, dynamic> result, String fallback) {
    if (result['message'] != null) {
      return result['message'].toString();
    }

    final errors = result['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;

      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }

      return firstError.toString();
    }

    return fallback;
  }
}
