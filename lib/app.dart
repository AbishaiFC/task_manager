import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/database/task_dao.dart';
import 'data/repositories/task_repository.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/tasks/task_list_screen.dart';
import 'services/auth/auth_service.dart';
import 'services/connectivity/connectivity_service.dart';
import 'data/sync/sync_service.dart';

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({
    super.key,
    required this.appDatabase,
    required this.taskDao,
    required this.taskRepository,
    required this.authService,
    required this.connectivityService,
    required this.syncService,
  });

  final AppDatabase appDatabase;
  final TaskDao taskDao;
  final TaskRepository taskRepository;
  final AuthService authService;
  final ConnectivityService connectivityService;
  final SyncService syncService;

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  @override
  void initState() {
    super.initState();
    // Trigger sync on connectivity recovery.
    widget.connectivityService.onConnectivityChanged.listen((online) {
      if (online && widget.authService.currentUser != null) {
        widget.syncService.syncNow();
      }
    });
  }

  @override
  void dispose() {
    widget.connectivityService.dispose();
    widget.taskRepository.dispose();
    widget.appDatabase.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: widget.appDatabase),
        Provider<TaskDao>.value(value: widget.taskDao),
        Provider<TaskRepository>.value(value: widget.taskRepository),
        Provider<AuthService>.value(value: widget.authService),
        Provider<ConnectivityService>.value(value: widget.connectivityService),
        Provider<SyncService>.value(value: widget.syncService),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return const TaskListScreen();
      },
    );
  }
}
