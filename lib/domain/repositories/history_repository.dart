// lib/domain/repositories/history_repository.dart
import '../entities/history_entry.dart';

abstract class HistoryRepository {
  Future<int> insertEntry(HistoryEntry entry);
  Future<List<HistoryEntry>> getAllEntries();
  Future<void> deleteEntry(int id);
  Future<void> deleteAllEntries();
  Future<String> exportToCsv();
}

