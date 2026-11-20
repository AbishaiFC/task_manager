import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import 'app_database.dart';

/// Data access object for tasks.
class TaskDao {
  TaskDao(this._db);
  final AppDatabase _db;

  Future<Database> get _database => _db.database;

  Future<void> insert(Task task) async {
    final db = await _database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Task task) async {
    final db = await _database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> softDelete(String id, DateTime updatedAt, int version) async {
    final db = await _database;
    await db.update(
      'tasks',
      {
        'is_deleted': 1,
        'is_synced': 0,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'version': version,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSynced(String id) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSyncedWithVersion(String id, int version) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'is_synced': 1, 'version': version},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Task?> getById(String id) async {
    final db = await _database;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Task.fromMap(rows.first);
  }

  Future<List<Task>> getAllActive() async {
    final db = await _database;
    final rows = await db.query(
      'tasks',
      where: 'is_deleted = 0',
      orderBy: 'updated_at DESC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getPending() async {
    final db = await _database;
    final rows = await db.query(
      'tasks',
      where: 'is_synced = 0',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getAllIncludingDeleted() async {
    final db = await _database;
    final rows = await db.query('tasks');
    return rows.map(Task.fromMap).toList();
  }

  Future<void> deletePermanently(String id) async {
    final db = await _database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertRemote(Task task) async {
    final db = await _database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
