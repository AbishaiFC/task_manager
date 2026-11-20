import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/database/task_dao.dart';
import 'data/repositories/task_repository.dart';
import 'services/auth/auth_service.dart';
import 'services/background/workmanager_service.dart';
import 'services/connectivity/connectivity_service.dart';
import 'data/sync/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await WorkManagerService.instance.initialize();
  await WorkManagerService.instance.registerPeriodicSync();

  final appDatabase = AppDatabase();
  final taskDao = TaskDao(appDatabase);
  final taskRepository = TaskRepository(taskDao);
  await taskRepository.refresh();

  final authService = AuthService();
  final connectivityService = ConnectivityService();
  await connectivityService.start();

  final syncService = SyncService(
    repository: taskRepository,
    dao: taskDao,
    auth: FirebaseAuth.instance,
  );

  runApp(TaskManagerApp(
    appDatabase: appDatabase,
    taskDao: taskDao,
    taskRepository: taskRepository,
    authService: authService,
    connectivityService: connectivityService,
    syncService: syncService,
  ));
}
