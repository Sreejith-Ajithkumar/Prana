import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/user_profile.dart';

class ProfileStorage {
  ProfileStorage._();

  static final ProfileStorage instance = ProfileStorage._();

  static const String _profileKey = 'prana_user_profile';
  static const String _onboardingCompletedKey = 'prana_onboarding_completed';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<void> saveProfile(UserProfile profile) async {
    final encodedProfile = jsonEncode(profile.toJson());

    await _preferences.setString(_profileKey, encodedProfile);

    await _preferences.setBool(_onboardingCompletedKey, true);
  }

  Future<UserProfile?> loadProfile() async {
    final encodedProfile = await _preferences.getString(_profileKey);

    if (encodedProfile == null || encodedProfile.isEmpty) {
      return null;
    }

    try {
      final decodedProfile = jsonDecode(encodedProfile);

      if (decodedProfile is! Map<String, dynamic>) {
        return null;
      }

      return UserProfile.fromJson(decodedProfile);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<bool> hasCompletedOnboarding() async {
    final completed = await _preferences.getBool(_onboardingCompletedKey);

    if (completed != true) {
      return false;
    }

    return await loadProfile() != null;
  }

  Future<void> clearProfile() async {
    await _preferences.remove(_profileKey);
    await _preferences.remove(_onboardingCompletedKey);
  }
}
