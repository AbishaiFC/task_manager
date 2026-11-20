import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/connectivity/connectivity_service.dart';
import '../../../data/sync/sync_service.dart';
import 'task_edit_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Initial sync on open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncService>().syncNow();
    });
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    final repo = context.read<TaskRepository>();
    await auth.signOut();
    await repo.purgeAll();
  }

  Future<void> _deleteTask(Task task) async {
    final repo = context.read<TaskRepository>();
    final sync = context.read<SyncService>();
    await repo.softDelete(task.id);
    sync.syncNow();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TaskRepository>();
    final connectivity = context.watch<ConnectivityService>();
    final sync = context.watch<SyncService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          _SyncStatusBar(
            online: connectivity.isOnline,
            syncing: sync.isSyncing,
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: repo.watchTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data ?? const <Task>[];
                if (tasks.isEmpty) {
                  return const _EmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _TaskTile(
                      task: task,
                      onTap: () => _openEdit(task),
                      onDelete: () => _deleteTask(task),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TaskEditScreen()),
    );
  }

  void _openEdit(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskEditScreen(task: task)),
    );
  }
}

class _SyncStatusBar extends StatelessWidget {
  const _SyncStatusBar({required this.online, required this.syncing});

  final bool online;
  final bool syncing;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TaskRepository>();
    // pending count derived from current tasks not synced
    return StreamBuilder<List<Task>>(
      stream: repo.watchTasks(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? const <Task>[];
        final pending = tasks.where((t) => !t.isSynced).length;
        String text;
        Color color;
        if (!online) {
          text = 'Offline${pending > 0 ? ' • $pending pending' : ''}';
          color = TokyoNightLight.yellow;
        } else if (syncing) {
          text = 'Syncing...';
          color = TokyoNightLight.blue;
        } else if (pending > 0) {
          text = '$pending pending changes';
          color = TokyoNightLight.orange;
        } else {
          text = 'All synced';
          color = TokyoNightLight.green;
        }
        return Container(
          width: double.infinity,
          color: color.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 8),
              Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: TokyoNightLight.outline),
          const SizedBox(height: 12),
          Text('No tasks yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Tap + to create your first task',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onTap,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(task.title),
        subtitle: Text(task.isSynced ? 'Synced' : 'Pending sync'),
        leading: Icon(
          task.isSynced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: task.isSynced ? TokyoNightLight.green : TokyoNightLight.orange,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onTap,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

