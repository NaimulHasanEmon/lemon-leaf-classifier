// lib/data/repositories/history_repository_impl.dart
import '../../core/constants.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/database_helper.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final DatabaseHelper dbHelper;

  HistoryRepositoryImpl({DatabaseHelper? helper})
      : dbHelper = helper ?? DatabaseHelper.instance;

  @override
  Future<int> insertEntry(HistoryEntry entry) async {
    final db = await dbHelper.database;
    return await db.insert(kHistoryTable, entry.toMap());
  }

  @override
  Future<List<HistoryEntry>> getAllEntries() async {
    final db = await dbHelper.database;
    final result = await db.query(kHistoryTable, orderBy: 'timestamp DESC');
    return result.map((json) => HistoryEntry.fromMap(json)).toList();
  }

  @override
  Future<void> deleteEntry(int id) async {
    final db = await dbHelper.database;
    await db.delete(kHistoryTable, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteAllEntries() async {
    final db = await dbHelper.database;
    await db.delete(kHistoryTable);
  }

  @override
  Future<String> exportToCsv() async {
    final entries = await getAllEntries();
    final StringBuffer csv = StringBuffer();
    csv.writeln('ID,Timestamp,Status,Predicted_Class,Probability,Failure_Reason');
    for (final e in entries) {
      final safeClass = e.predictedClass != null ? '"${e.predictedClass}"' : '""';
      final safeReason = e.failureReason != null ? '"${e.failureReason!.replaceAll('"', '""')}"' : '""';
      final probStr = e.probability != null ? e.probability!.toStringAsFixed(4) : '';
      csv.writeln('${e.id},"${e.timestamp.toIso8601String()}",${e.status},$safeClass,$probStr,$safeReason');
    }
    return csv.toString();
  }
}

