import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/weight_entry.dart';

class WeightStorage {
  WeightStorage._();

  static final WeightStorage instance = WeightStorage._();

  static const String _weightKey = 'prana_weight_entries';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<WeightEntry>> loadEntries() async {
    final encoded = await _preferences.getString(_weightKey);

    if (encoded == null || encoded.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(encoded);

      if (decoded is! List<dynamic>) {
        return [];
      }

      final entries = decoded
          .map(
            (item) =>
                WeightEntry.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      entries.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

      return entries;
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    } on ArgumentError {
      return [];
    }
  }

  Future<void> saveEntries(List<WeightEntry> entries) async {
    final sortedEntries = [...entries]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final encoded = jsonEncode(
      sortedEntries.map((entry) => entry.toJson()).toList(),
    );

    await _preferences.setString(_weightKey, encoded);
  }

  Future<void> addEntry(WeightEntry entry) async {
    if (entry.weightKg <= 0) {
      throw ArgumentError.value(
        entry.weightKg,
        'weightKg',
        'Weight must be greater than zero.',
      );
    }

    final entries = await loadEntries();

    await saveEntries([...entries, entry]);
  }

  Future<void> updateEntry(WeightEntry updatedEntry) async {
    if (updatedEntry.weightKg <= 0) {
      throw ArgumentError.value(
        updatedEntry.weightKg,
        'weightKg',
        'Weight must be greater than zero.',
      );
    }

    final entries = await loadEntries();

    final index = entries.indexWhere((entry) => entry.id == updatedEntry.id);

    if (index == -1) {
      throw StateError('Weight entry not found.');
    }

    entries[index] = updatedEntry;

    await saveEntries(entries);
  }

  Future<void> deleteEntry(String entryId) async {
    final entries = await loadEntries();

    final updatedEntries = entries
        .where((entry) => entry.id != entryId)
        .toList();

    await saveEntries(updatedEntries);
  }

  Future<List<WeightEntry>> loadEntriesForDate(DateTime date) async {
    final entries = await loadEntries();

    return entries.where((entry) {
      final measuredAt = entry.measuredAt;

      return measuredAt.year == date.year &&
          measuredAt.month == date.month &&
          measuredAt.day == date.day;
    }).toList();
  }

  Future<WeightEntry?> loadLatestEntry() async {
    final entries = await loadEntries();

    if (entries.isEmpty) {
      return null;
    }

    return entries.last;
  }

  Future<void> clearEntries() async {
    await _preferences.remove(_weightKey);
  }
}
