import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager/data/models/task.dart';
import 'package:task_manager/data/sync/conflict_resolver.dart';

void main() {
  Task make({
    required String id,
    required String title,
    required DateTime updatedAt,
    bool isDeleted = false,
    int version = 1,
    bool isSynced = true,
  }) {
    return Task(
      id: id,
      title: title,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      version: version,
      isSynced: isSynced,
    );
  }

  test('remote newer wins', () {
    final local = make(id: '1', title: 'old', updatedAt: DateTime(2020));
    final remote = make(id: '1', title: 'new', updatedAt: DateTime(2021));
    final resolved = ConflictResolver.resolve(local: local, remote: remote);
    expect(resolved.title, 'new');
  });

  test('local newer wins', () {
    final local = make(id: '1', title: 'local', updatedAt: DateTime(2021));
    final remote = make(id: '1', title: 'remote', updatedAt: DateTime(2020));
    final resolved = ConflictResolver.resolve(local: local, remote: remote);
    expect(resolved.title, 'local');
  });

  test('remote deletion wins when newer', () {
    final local = make(id: '1', title: 'active', updatedAt: DateTime(2020));
    final remote = make(id: '1', title: 'active', updatedAt: DateTime(2021), isDeleted: true);
    final resolved = ConflictResolver.resolve(local: local, remote: remote);
    expect(resolved.isDeleted, isTrue);
  });

  test('null local returns remote', () {
    final remote = make(id: '1', title: 'r', updatedAt: DateTime(2021));
    final resolved = ConflictResolver.resolve(local: null, remote: remote);
    expect(resolved, remote);
  });

  test('version conflict detection', () {
    expect(ConflictResolver.isVersionConflict(localVersion: 1, remoteVersion: 2), isTrue);
    expect(ConflictResolver.isVersionConflict(localVersion: 2, remoteVersion: 2), isFalse);
  });

  test('equal timestamps tie-break by version', () {
    final t = DateTime(2021);
    final local = make(id: '1', title: 'local', updatedAt: t, version: 1);
    final remote = make(id: '1', title: 'remote', updatedAt: t, version: 2);
    final resolved = ConflictResolver.resolve(local: local, remote: remote);
    expect(resolved.title, 'remote');
  });
}
