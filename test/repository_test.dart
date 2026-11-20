import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:task_manager/data/database/app_database.dart';
import 'package:task_manager/data/database/task_dao.dart';
import 'package:task_manager/data/models/task.dart';
import 'package:task_manager/data/repositories/task_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late TaskDao dao;
  late TaskRepository repo;

  setUp(() async {
    db = AppDatabase(path: ':memory:');
    dao = TaskDao(db);
    repo = TaskRepository(dao);
    await repo.refresh();
  });

  tearDown(() async {
    repo.dispose();
    await db.close();
  });

  test('create task persists and streams', () async {
    final t = Task(title: 'Buy milk');
    await repo.create(t);
    final list = await repo.watchTasks().first;
    expect(list.length, 1);
    expect(list.first.title, 'Buy milk');
    expect(list.first.isSynced, isFalse);
  });

  test('soft delete removes from active list', () async {
    final t = Task(title: 'Temp');
    await repo.create(t);
    await repo.softDelete(t.id);
    final list = await repo.watchTasks().first;
    expect(list, isEmpty);
    final all = await dao.getAllIncludingDeleted();
    expect(all.length, 1);
    expect(all.first.isDeleted, isTrue);
  });

  test('update marks unsynced', () async {
    final t = Task(title: 'A');
    await repo.create(t);
    await repo.markSynced(t.id);
    final updated = t.copyWith(title: 'B', isSynced: false, version: t.version + 1);
    await repo.update(updated);
    final fetched = await repo.getById(t.id);
    expect(fetched!.title, 'B');
    expect(fetched.isSynced, isFalse);
  });

  test('pending returns unsynced', () async {
    final t1 = Task(title: 'X');
    final t2 = Task(title: 'Y');
    await repo.create(t1);
    await repo.create(t2);
    await repo.markSynced(t1.id);
    final pending = await repo.getPending();
    expect(pending.length, 1);
    expect(pending.first.id, t2.id);
  });
}
