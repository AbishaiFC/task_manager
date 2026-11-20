import 'dart:async';

import '../models/task.dart';
import '../database/task_dao.dart';

/// Single source of truth for tasks: all reads come from local SQLite.
class TaskRepository {
  TaskRepository(this._dao);

  final TaskDao _dao;

  final StreamController<List<Task>> _controller =
      StreamController<List<Task>>.broadcast();

  List<Task> _current = const [];
  bool _closed = false;

  Stream<List<Task>> watchTasks() async* {
    // Emit current cached value immediately, then follow updates.
    yield _current;
    yield* _controller.stream;
  }

  List<Task> get currentTasks => List.unmodifiable(_current);

  Future<void> refresh() async {
    _current = await _dao.getAllActive();
    if (!_closed) _controller.add(_current);
  }

  Future<void> create(Task task) async {
    await _dao.insert(task);
    await refresh();
  }

  Future<void> update(Task task) async {
    await _dao.update(task);
    await refresh();
  }

  Future<void> softDelete(String id) async {
    final existing = await _dao.getById(id);
    if (existing == null) return;
    final now = DateTime.now().toUtc();
    await _dao.softDelete(id, now, existing.version + 1);
    await refresh();
  }

  Future<Task?> getById(String id) => _dao.getById(id);

  Future<List<Task>> getPending() => _dao.getPending();

  Future<void> markSynced(String id) async {
    await _dao.markSynced(id);
    await refresh();
  }

  Future<void> markSyncedWithVersion(String id, int version) async {
    await _dao.markSyncedWithVersion(id, version);
    await refresh();
  }

  Future<void> upsertFromRemote(Task task) async {
    await _dao.upsertRemote(task);
    await refresh();
  }

  Future<void> purgeAll() async {
    final all = await _dao.getAllIncludingDeleted();
    for (final t in all) {
      await _dao.deletePermanently(t.id);
    }
    await refresh();
  }

  void dispose() {
    _closed = true;
    _controller.close();
  }
}
