import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AppleHealthAuthorizationStore {
  Future<bool> hasRequestedAuthorization();

  Future<void> markAuthorizationRequested();
}

class SharedPreferencesAppleHealthAuthorizationStore
    implements AppleHealthAuthorizationStore {
  SharedPreferencesAppleHealthAuthorizationStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _authorizationRequestedKey =
      'prana_apple_health_authorization_requested';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> hasRequestedAuthorization() async {
    return await _preferences.getBool(_authorizationRequestedKey) ?? false;
  }

  @override
  Future<void> markAuthorizationRequested() {
    return _preferences.setBool(_authorizationRequestedKey, true);
  }
}
