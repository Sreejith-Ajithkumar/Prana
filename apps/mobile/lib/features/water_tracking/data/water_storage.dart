import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/water_entry.dart';

class WaterStorage {
  WaterStorage._();

  static final WaterStorage instance = WaterStorage._();

  static const String _waterKey = 'prana_water_entries';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<WaterEntry>> loadEntries() async {
    final encoded = await _preferences.getString(_waterKey);

    if (encoded == null || encoded.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(encoded);

      if (decoded is! List<dynamic>) {
        return [];
      }

      return decoded
          .map((item) => WaterEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    } on ArgumentError {
      return [];
    }
  }

  Future<void> saveEntries(List<WaterEntry> entries) async {
    final encoded = jsonEncode(entries.map((entry) => entry.toJson()).toList());

    await _preferences.setString(_waterKey, encoded);
  }

  Future<void> addEntry(WaterEntry entry) async {
    final entries = await loadEntries();

    await saveEntries([...entries, entry]);
  }

  Future<void> deleteEntry(String entryId) async {
    final entries = await loadEntries();

    final updatedEntries = entries
        .where((entry) => entry.id != entryId)
        .toList();

    await saveEntries(updatedEntries);
  }

  Future<List<WaterEntry>> loadEntriesForDate(DateTime date) async {
    final entries = await loadEntries();

    final filteredEntries = entries.where((entry) {
      final loggedAt = entry.loggedAt;

      return loggedAt.year == date.year &&
          loggedAt.month == date.month &&
          loggedAt.day == date.day;
    }).toList();

    filteredEntries.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    return filteredEntries;
  }

  Future<void> clearEntries() async {
    await _preferences.remove(_waterKey);
  }
}
