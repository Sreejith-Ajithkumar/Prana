import 'package:shared_preferences/shared_preferences.dart';

abstract interface class CustomFoodStorageBackend {
  Future<String?> read();

  Future<void> write(String value);
}

class SharedPreferencesCustomFoodStorageBackend
    implements CustomFoodStorageBackend {
  SharedPreferencesCustomFoodStorageBackend({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const String storageKey = 'prana_custom_foods_v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() {
    return _preferences.getString(storageKey);
  }

  @override
  Future<void> write(String value) {
    return _preferences.setString(storageKey, value);
  }
}
