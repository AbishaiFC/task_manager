import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/database/app_database.dart';
import '../../data/database/task_dao.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/sync/sync_service.dart';

const String syncTaskName = 'task_manager_sync';
const String periodicSyncTask = 'task_manager_periodic_sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();
      final db = AppDatabase();
      final dao = TaskDao(db);
      final repo = TaskRepository(dao);
      await repo.refresh();
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await db.close();
        return true;
      }
      final sync = SyncService(repository: repo, dao: dao, auth: auth);
      await sync.syncNow();
      await db.close();
    } catch (_) {
      // Swallow; WorkManager will retry per policy.
    }
    return true;
  });
}

class WorkManagerService {
  WorkManagerService._();
  static final WorkManagerService instance = WorkManagerService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    _initialized = true;
  }

  Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      periodicSyncTask,
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  }

  Future<void> registerOneTimeSync() async {
    await Workmanager().registerOneOffTask(
      '${syncTaskName}_once_${DateTime.now().millisecondsSinceEpoch}',
      syncTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
    );
  }

  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
