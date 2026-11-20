import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local SQLite database wrapper.
class AppDatabase {
  AppDatabase({this._path});

  final String? _path;
  Database? _db;

  static const int _version = 2;

  static const String createTasksTable = '''
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  is_synced INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  version INTEGER NOT NULL DEFAULT 1
);
''';

  static const String createIndexSynced = 'CREATE INDEX IF NOT EXISTS idx_tasks_is_synced ON tasks(is_synced);';
  static const String createIndexDeleted = 'CREATE INDEX IF NOT EXISTS idx_tasks_is_deleted ON tasks(is_deleted);';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = _path ?? await getDatabasesPath();
    final fullPath = _path ?? p.join(dbPath, 'task_manager.db');
    return openDatabase(
      fullPath,
      version: _version,
      onCreate: (db, version) async {
        await db.execute(createTasksTable);
        await db.execute(createIndexSynced);
        await db.execute(createIndexDeleted);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE tasks ADD COLUMN version INTEGER NOT NULL DEFAULT 1;');
          } catch (_) {
            // Column may already exist.
          }
        }
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
