import 'package:uuid/uuid.dart';

/// Domain model representing a task.
class Task {
  Task({
    String? id,
    required this.title,
    this.isSynced = false,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.version = 1,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  final String id;
  final String title;
  final bool isSynced;
  final DateTime updatedAt;
  final bool isDeleted;
  final int version;

  Task copyWith({
    String? id,
    String? title,
    bool? isSynced,
    DateTime? updatedAt,
    bool? isDeleted,
    int? version,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'is_synced': isSynced ? 1 : 0,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'version': version,
    };
  }

  factory Task.fromMap(Map<String, Object?> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      version: map['version'] as int? ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          id == other.id &&
          title == other.title &&
          isSynced == other.isSynced &&
          updatedAt == other.updatedAt &&
          isDeleted == other.isDeleted &&
          version == other.version;

  @override
  int get hashCode => Object.hash(id, title, isSynced, updatedAt, isDeleted, version);
}
