import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../database/task_dao.dart';
import 'conflict_resolver.dart';

/// Bidirectional synchronization service between SQLite and Firestore.
class SyncService {
  SyncService({
    required this.repository,
    required this.dao,
    required this.auth,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final TaskRepository repository;
  final TaskDao dao;
  final FirebaseAuth auth;
  final FirebaseFirestore _firestore;

  bool _syncing = false;

  bool get isSyncing => _syncing;

  CollectionReference<Map<String, dynamic>>? _tasksCollection() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('tasks');
  }

  /// Performs a full sync cycle. Safe to call concurrently (serialized).
  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      final collection = _tasksCollection();
      if (collection == null) return;

      await _uploadPending(collection);
      await _downloadRemote(collection);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _uploadPending(CollectionReference<Map<String, dynamic>> collection) async {
    final pending = await repository.getPending();
    for (final task in pending) {
      try {
        final docRef = collection.doc(task.id);
        final remoteSnap = await docRef.get();
        if (remoteSnap.exists) {
          final remoteData = remoteSnap.data()!;
          final remoteVersion = (remoteData['version'] as int?) ?? 1;
          final remoteUpdated = _parseDate(remoteData['updatedAt']);
          // Conflict: remote is newer -> resolve locally instead of overwriting.
          if (ConflictResolver.isVersionConflict(
                localVersion: task.version,
                remoteVersion: remoteVersion,
              ) ||
              (remoteUpdated != null && remoteUpdated.isAfter(task.updatedAt))) {
            final remoteTask = _fromFirestore(remoteSnap.id, remoteData);
            final merged = ConflictResolver.resolve(local: task, remote: remoteTask);
            if (merged != task) {
              await repository.upsertFromRemote(merged);
            }
            continue;
          }
        }

        await docRef.set({
          'id': task.id,
          'title': task.title,
          'isDeleted': task.isDeleted,
          'updatedAt': Timestamp.fromDate(task.updatedAt.toUtc()),
          'version': task.version,
          'uid': auth.currentUser!.uid,
        }, SetOptions(merge: false));

        await repository.markSyncedWithVersion(task.id, task.version);
      } catch (_) {
        // Keep pending; will retry.
      }
    }
  }

  Future<void> _downloadRemote(CollectionReference<Map<String, dynamic>> collection) async {
    try {
      final snapshot = await collection.get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final remoteTask = _fromFirestore(doc.id, data);
        final local = await dao.getById(remoteTask.id);
        final merged = ConflictResolver.resolve(local: local, remote: remoteTask);
        if (local == null || merged != local) {
          // Preserve pending local changes: if local is unsynced and wins, skip overwrite.
          if (local != null && !local.isSynced && merged == local) {
            continue;
          }
          await repository.upsertFromRemote(merged);
          if (merged.isSynced == false) {
            // mark synced since it came from remote
          }
          await dao.markSynced(merged.id);
          await repository.refresh();
        }
      }
    } catch (_) {
      // ignore; retry later
    }
  }

  Task _fromFirestore(String id, Map<String, dynamic> data) {
    return Task(
      id: (data['id'] as String?) ?? id,
      title: (data['title'] as String?) ?? '',
      isSynced: true,
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now().toUtc(),
      isDeleted: (data['isDeleted'] as bool?) ?? false,
      version: (data['version'] as int?) ?? 1,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is String) {
      try {
        return DateTime.parse(value).toUtc();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
