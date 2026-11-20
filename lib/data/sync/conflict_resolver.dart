import '../models/task.dart';

/// Conflict resolution combining Last-Write-Wins and version control.
class ConflictResolver {
  ConflictResolver._();

  /// Returns the task that should be persisted locally given a local (possibly null)
  /// and a remote version of the same id.
  static Task resolve({Task? local, required Task remote}) {
    if (local == null) return remote;

    // Tombstone propagation: a deletion wins unless local has a strictly newer update.
    if (remote.isDeleted && !local.isDeleted) {
      if (!remote.updatedAt.isBefore(local.updatedAt)) {
        return remote;
      }
      // local newer update resurrects / keeps active
      return local;
    }
    if (local.isDeleted && !remote.isDeleted) {
      if (!local.updatedAt.isBefore(remote.updatedAt)) {
        return local;
      }
      return remote;
    }

    // Last-Write-Wins by updated_at.
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      return remote;
    }
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return local;
    }

    // Equal timestamps: deterministic tie-break using version, then id.
    if (remote.version > local.version) return remote;
    if (local.version > remote.version) return local;

    // Final tie-break: keep local pending changes to avoid clobbering unsynced edits.
    if (!local.isSynced) return local;
    return remote;
  }

  /// Whether a remote record is newer than the local one (should overwrite).
  static bool remoteWins(Task local, Task remote) {
    final resolved = resolve(local: local, remote: remote);
    return resolved == remote;
  }

  /// Detects a concurrent modification conflict during upload.
  static bool isVersionConflict({
    required int localVersion,
    required int remoteVersion,
  }) {
    return remoteVersion > localVersion;
  }
}
