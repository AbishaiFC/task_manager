<style>
:root {
  --bg: #e1e2e7;
  --fg: #343b58;
  --surface: #d5d6db;
  --surface-alt: #c4c8da;
  --primary: #2e7de9;
  --secondary: #007197;
  --accent: #9854f1;
  --success: #587539;
  --warning: #8c6c3e;
  --danger: #f52a65;
  --outline: #a8adbd;
}
.report-card {
  background: var(--surface);
  border: 1px solid var(--outline);
  border-radius: 12px;
  padding: 16px 20px;
  margin: 12px 0;
}
.report-title {
  color: var(--primary);
  font-size: 2em;
  font-weight: 700;
  margin-bottom: 4px;
}
.report-subtitle {
  color: var(--secondary);
  font-size: 1.1em;
  font-weight: 500;
}
.badge {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 999px;
  font-size: 0.8em;
  font-weight: 600;
  background: var(--primary);
  color: #ffffff;
  margin: 2px;
}
.code-block {
  background: #1a1b26;
  color: #c0caf5;
  border-radius: 8px;
  padding: 12px;
  font-family: monospace;
  font-size: 0.85em;
  overflow-x: auto;
}
</style>

<div class="report-card" style="text-align:center;">
  <div class="report-title">Reporte Técnico</div>
  <div class="report-subtitle">Aplicación Móvil Offline-First con Sincronización Bidireccional</div>
  <p style="color:var(--fg); margin-top:8px;">Gestor de Tareas — Flutter · SQLite · Firebase</p>
</div>

<div class="report-card">
  <h3 style="color:var(--primary);">Credenciales académicas</h3>
  <table style="width:100%; border-collapse:collapse;">
    <tr><td style="padding:4px 8px; font-weight:600; color:var(--secondary);">Institución</td><td style="padding:4px 8px;">Universidad Tecnológica de Xicotepec de Juárez</td></tr>
    <tr><td style="padding:4px 8px; font-weight:600; color:var(--secondary);">Materia</td><td style="padding:4px 8px;">Desarrollo Móvil Integral</td></tr>
    <tr><td style="padding:4px 8px; font-weight:600; color:var(--secondary);">Profesor</td><td style="padding:4px 8px;">M.T.I. Cupertino Luna Trejo</td></tr>
    <tr><td style="padding:4px 8px; font-weight:600; color:var(--secondary);">Grado y grupo</td><td style="padding:4px 8px;">10° B</td></tr>
    <tr><td style="padding:4px 8px; font-weight:600; color:var(--secondary);">Alumno</td><td style="padding:4px 8px;">Osvaldo Abishai Flores Campos</td></tr>
    <tr><td style="padding:4px 8px; font-weight:600; color:var(--secondary);">Matrícula</td><td style="padding:4px 8px;">230413</td></tr>
    <tr><td style="padding:4px 8px; font-weight:600; color:var(--secondary);">Fecha</td><td style="padding:4px 8px;">Noviembre 2026</td></tr>
  </table>
</div>

---

# 1. Objetivo

Diseñar e implementar una aplicación móvil Android con arquitectura **Offline-First** que permita gestionar tareas mediante operaciones CRUD (Create, Read, Update, Delete) sin depender de la conectividad a Internet, sincronizando automáticamente los cambios pendientes con un backend remoto (Firebase Authentication + Cloud Firestore) cuando se restablezca la conexión.

**Objetivos específicos:**

- Garantizar persistencia local confiable mediante SQLite como única fuente de verdad (Single Source of Truth).
- Implementar sincronización bidireccional idempotente entre el dispositivo y Cloud Firestore.
- Resolver conflictos mediante la estrategia *Last-Write-Wins* combinada con control de versiones.
- Ejecutar sincronizaciones en segundo plano mediante Android WorkManager.
- Proteger credenciales mediante almacenamiento seguro (`flutter_secure_storage`).
- Validar la identidad del usuario mediante reglas de seguridad de Firestore basadas en UID.
- Construir una interfaz coherente basada en principios de Material Design y la paleta **Tokyo Night Light**.

---

# 2. Desarrollo

## 2.1 Stack tecnológico

<div class="report-card">
  <span class="badge">Flutter 3.47.7</span>
  <span class="badge">Dart 3.13.5</span>
  <span class="badge">sqflite</span>
  <span class="badge">Firebase Auth</span>
  <span class="badge">Cloud Firestore</span>
  <span class="badge">WorkManager</span>
  <span class="badge">connectivity_plus</span>
  <span class="badge">flutter_secure_storage</span>
  <span class="badge">provider</span>
  <span class="badge">uuid</span>
</div>

La plataforma objetivo es **Android exclusivamente**. Todas las decisiones arquitectónicas priorizan el ecosistema Android: Gradle, AndroidManifest, WorkManager, ConnectivityManager.

## 2.2 Patrones arquitectónicos utilizados

### Single Source of Truth (SSOT)

La base de datos SQLite es la única fuente de verdad para la interfaz de usuario. La UI consume únicamente `Stream`s locales; ninguna respuesta del backend actualiza la interfaz directamente. El flujo es:

```
UI (Flutter)  →  Streams locales  →  SQLite  →  SyncService  →  Firebase
```

### Repository Pattern

`TaskRepository` centraliza el acceso a datos, expone `watchTasks()` como `Stream<List<Task>>` y gestiona el refresco tras cada mutación. La UI nunca ejecuta SQL ni accede a Firebase directamente.

### Provider (State Management / DI)

Se utiliza `provider` para inyectar dependencias (`TaskRepository`, `AuthService`, `ConnectivityService`, `SyncService`) en el árbol de widgets sin acoplar la UI a implementaciones concretas.

### DAO (Data Access Object)

`TaskDao` encapsula todas las operaciones SQL sobre la tabla `tasks`, manteniendo el repositorio libre de detalles de persistencia.

### Service Layer

Servicios independientes para autenticación (`AuthService`), conectividad (`ConnectivityService`), sincronización (`SyncService`) y trabajo en segundo plano (`WorkManagerService`), cada uno con una responsabilidad única.

## 2.3 Modelo de datos

### Esquema SQLite

```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    is_synced INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0,
    version INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX idx_tasks_is_synced ON tasks(is_synced);
CREATE INDEX idx_tasks_is_deleted ON tasks(is_deleted);
```

### Descripción de campos

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | TEXT (PK) | UUID generado en el cliente. Identificador permanente e idempotente. |
| `title` | TEXT | Descripción de la tarea. |
| `is_synced` | INTEGER | `0` pendiente, `1` sincronizado. |
| `updated_at` | TEXT (ISO-8601) | Marca temporal para Last-Write-Wins. |
| `is_deleted` | INTEGER | Borrado lógico: `0` activo, `1` eliminado (tombstone). |
| `version` | INTEGER | Control de versiones para detectar conflictos concurrentes. |

### Modelo de dominio (Dart)

```dart
class Task {
  final String id;          // UUID v4
  final String title;
  final bool isSynced;
  final DateTime updatedAt; // UTC
  final bool isDeleted;
  final int version;
}
```

### Reglas de persistencia

1. Todo registro se genera inicialmente en SQLite.
2. Toda creación o modificación establece `is_synced = 0`.
3. Toda modificación actualiza `updated_at` y incrementa `version`.
4. Las eliminaciones son lógicas (`is_deleted = 1`) y se conservan hasta confirmación del backend.
5. La interfaz excluye registros con `is_deleted = 1`.

## 2.4 Cifrado y seguridad

### Almacenamiento seguro

Se utiliza `flutter_secure_storage` para proteger información sensible del dispositivo. Firebase Authentication administra automáticamente los tokens de acceso y refresh (persistencia segura interna); `flutter_secure_storage` se emplea adicionalmente para cachear el UID del usuario autenticado, evitando almacenarlo en SQLite o archivos de texto plano.

| Tipo de dato | Mecanismo |
|---|---|
| Tokens de autenticación (access/refresh) | Firebase Auth (gestión automática, almacenamiento seguro interno) |
| UID del usuario | `flutter_secure_storage` |
| Datos funcionales de tareas | SQLite (no sensibles) |

### Validación de identidad

Cada documento remoto se almacena bajo la ruta `users/{uid}/tasks/{taskId}`, garantizando aislamiento por usuario. Las reglas de seguridad de Firestore validan que `request.auth.uid == uid`.

### Limpieza de sesión

Al cerrar sesión se ejecuta `purgeAll()` sobre SQLite, se invalidan las operaciones de sincronización pendientes (el `SyncService` verifica `currentUser != null` antes de operar) y se eliminan las claves de `flutter_secure_storage`. WorkManager deja de procesar tareas del usuario anterior porque el callback valida la sesión activa.

## 2.5 Reglas de backend (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/tasks/{taskId} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

Estas reglas garantizan que:
- Un usuario solo accede a sus propios registros.
- No puede modificar ni consultar datos de otro UID.
- Las operaciones sin autenticación son rechazadas.

Las reglas fueron desplegadas mediante Firebase CLI (`firebase deploy --only firestore:rules`) sobre el proyecto `task-manager-56ab4`.

## 2.6 Sincronización y resolución de conflictos

### Sincronización de cambios locales

Cuando un registro tiene `is_synced = 0`, el `SyncService` lo identifica, verifica conectividad, obtiene el UID, envía el documento a Firestore con `set(..., merge: false)` (idempotente por UUID) y solo marca `is_synced = 1` tras la confirmación del backend.

### Sincronización de cambios remotos

Se recuperan todos los documentos del usuario y se comparan con la versión local. Se aplica `ConflictResolver.resolve()` para decidir qué versión prevalece, actualizando SQLite y notificando a la UI mediante Streams.

### Resolución de conflictos (LWW + control de versiones)

- **Last-Write-Wins:** se compara `updated_at`; la versión más reciente prevalece.
- **Control de versiones:** el campo `version` detecta modificaciones concurrentes. Si el remoto tiene una versión mayor, se resuelve la fusión sin sobrescribir cambios locales más recientes.
- **Desempate determinista:** ante timestamps iguales, prevalece la versión mayor; si también coinciden, se conserva el cambio local no sincronizado.
- **Tombstones:** los borrados lógicos se propagan y no reaparecen al descargar datos remotos.

### Ejecución en segundo plano

- `WorkManager` registra una tarea periódica (cada 15 minutos) y tareas únicas (one-off) con restricción `NetworkType.connected`.
- Política de reintento exponencial (`BackoffPolicy.exponential`).
- `ConnectivityService` (basado en `connectivity_plus` / ConnectivityManager) dispara sincronización inmediata al recuperar la red mientras la app está abierta.

### Idempotencia

Las escrituras usan el UUID del cliente como clave de documento (`collection.doc(task.id).set(...)`), garantizando un único registro remoto por UUID y usuario, incluso ante reintentos o pérdida de respuesta.

## 2.7 Interfaz de usuario

La interfaz sigue principios de **Material Design** (Material 3) con la paleta **Tokyo Night Light**:

<div class="report-card">
  <table style="width:100%; border-collapse:collapse;">
    <tr><th style="text-align:left; padding:4px 8px; color:var(--secondary);">Color</th><th style="text-align:left; padding:4px 8px; color:var(--secondary);">Hex</th><th style="text-align:left; padding:4px 8px; color:var(--secondary);">Uso</th></tr>
    <tr><td style="padding:4px 8px;">Fondo</td><td style="padding:4px 8px;"><code>#E1E2E7</code></td><td style="padding:4px 8px;">Scaffold background</td></tr>
    <tr><td style="padding:4px 8px;">Texto principal</td><td style="padding:4px 8px;"><code>#343B58</code></td><td style="padding:4px 8px;">Foreground</td></tr>
    <tr><td style="padding:4px 8px;">Superficie</td><td style="padding:4px 8px;"><code>#D5D6DB</code></td><td style="padding:4px 8px;">Cards, AppBar</td></tr>
    <tr><td style="padding:4px 8px;">Primario</td><td style="padding:4px 8px;"><code>#2E7DE9</code></td><td style="padding:4px 8px;">Botones, FAB, acentos</td></tr>
    <tr><td style="padding:4px 8px;">Éxito</td><td style="padding:4px 8px;"><code>#587539</code></td><td style="padding:4px 8px;">Sincronizado</td></tr>
    <tr><td style="padding:4px 8px;">Advertencia</td><td style="padding:4px 8px;"><code>#8C6C3E</code></td><td style="padding:4px 8px;">Sin conexión</td></tr>
    <tr><td style="padding:4px 8px;">Error</td><td style="padding:4px 8px;"><code>#F52A65</code></td><td style="padding:4px 8px;">Errores</td></tr>
  </table>
</div>

**Pantallas implementadas:**
- Login / Registro (Firebase Auth).
- Listado de tareas con indicador de estado de sincronización.
- Crear tarea.
- Editar tarea.
- Eliminación lógica (desaparece inmediatamente de la lista).

## 2.8 Fotografías del sistema

### Pantalla de inicio de sesión (emulador Android)

![Pantalla de login](docs/screenshot_login.png)

*Figura 1. Pantalla de autenticación de la aplicación ejecutándose en el emulador Android (Medium Phone API 37).*

### Consola de Firebase — Proyecto configurado

El proyecto `task-manager-56ab4` fue configurado con:
- App Android registrada (paquete `com.apren.taskmanager.task_manager`).
- Autenticación por correo/contraseña habilitada.
- Base de datos Firestore (default) creada en región `nam5`.
- Reglas de seguridad desplegadas.

### Estructura del proyecto

```
lib/
├── main.dart
├── app.dart
├── core/theme/app_theme.dart
├── data/
│   ├── models/task.dart
│   ├── database/app_database.dart
│   ├── database/task_dao.dart
│   ├── repositories/task_repository.dart
│   └── sync/
│       ├── conflict_resolver.dart
│       └── sync_service.dart
├── services/
│   ├── auth/auth_service.dart
│   ├── connectivity/connectivity_service.dart
│   └── background/workmanager_service.dart
└── presentation/
    ├── screens/auth/login_screen.dart
    └── screens/tasks/
        ├── task_list_screen.dart
        └── task_edit_screen.dart
```

---

# 3. Conclusión

Se implementó exitosamente una aplicación móvil Android con arquitectura **Offline-First** que cumple con los criterios de aceptación establecidos:

- ✅ CRUD completamente funcional sobre SQLite.
- ✅ Persistencia local confiable (Single Source of Truth).
- ✅ UI alimentada exclusivamente por Streams locales.
- ✅ Funcionamiento completo sin conexión.
- ✅ Persistencia después del cierre forzado.
- ✅ Sincronización automática al recuperar conectividad.
- ✅ Sincronización bidireccional (subida y descarga).
- ✅ Resolución de conflictos mediante LWW + control de versiones.
- ✅ Prevención de duplicados mediante UUID.
- ✅ Borrado lógico sincronizado (tombstones).
- ✅ Ejecución en segundo plano mediante WorkManager.
- ✅ Protección de credenciales con `flutter_secure_storage`.
- ✅ Validación de UID mediante reglas de seguridad de Firestore.
- ✅ Limpieza de datos locales al cerrar sesión.
- ✅ Interfaz basada en Material Design y paleta Tokyo Night Light.

La solución se comporta como una aplicación de producción: tolera interrupciones de conectividad, evita duplicados, resuelve conflictos y no depende de mantener la aplicación abierta. Las pruebas unitarias (11/11 aprobadas) y la compilación exitosa del APK de depuración validan la implementación.

---

<div class="report-card" style="text-align:center; color:var(--secondary);">
  <em>Reporte generado como evidencia de documentación técnica — Desarrollo Móvil Integral</em>
</div>
