import '../entities/weight_entry.dart';

abstract interface class WeightEntryStore {
  Future<List<WeightEntry>> loadEntries();

  Future<void> saveEntries(List<WeightEntry> entries);
}
