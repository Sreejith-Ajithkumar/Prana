import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/water_entry.dart';

class WaterStorage {
  WaterStorage._();

  static final WaterStorage instance = WaterStorage._();

  static const String _waterKey = 'prana_water_entries';

  Future<SharedPreferences> _getPreferences() {
    return SharedPreferences.getInstance();
  }

  Future<List<WaterEntry>> loadEntries() async {
    try {
      final preferences = await _getPreferences();

      final encoded = preferences.getString(_waterKey);

      if (encoded == null || encoded.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(encoded);

      if (decoded is! List<dynamic>) {
        return [];
      }

      return decoded
          .map(
            (item) =>
                WaterEntry.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    } on ArgumentError {
      return [];
    } catch (error, stackTrace) {
      debugPrint('WATER STORAGE LOAD ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);

      return [];
    }
  }

  Future<void> saveEntries(List<WaterEntry> entries) async {
    final preferences = await _getPreferences();

    final encoded = jsonEncode(entries.map((entry) => entry.toJson()).toList());

    await preferences.setString(_waterKey, encoded);
  }

  Future<void> addEntry(WaterEntry entry) async {
    final entries = await loadEntries();

    final updatedEntries = [...entries, entry];

    await saveEntries(updatedEntries);
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
    final preferences = await _getPreferences();

    await preferences.remove(_waterKey);
  }
}
