# Offline Auth DAO Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el sistema de autenticación offline-first con DAO usando Drift, permitiendo registro e inicio de sesión sin conexión.

**Architecture:** Agregar tabla OfflineUsers al database Drift existente, crear OfflineAuthDao con métodos CRUD, integrar con AuthService existente para flujo offline-first.

**Tech Stack:** Drift, SQLite, package argon2 para hashing.

---

## Task 1: Agregar OfflineUsers Table al Database

**Files:**
- Modify: `lib/data/local/database.dart`

- [ ] **Step 1: Agregar tabla OfflineUsers**

Agregar esta clase de tabla ANTES de la clase AppDatabase:

```dart
class OfflineUsers extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get passwordHash => text().named('password_hash')();
  TextColumn get fullName => text().nullable().named('full_name')();
  TextColumn get country => text().nullable()();
  TextColumn get accountType => text().nullable().named('account_type')();
  TextColumn get hostingMode => text().nullable().named('hosting_mode')();
  TextColumn get lastLogin => text().nullable().named('last_login')();
  TextColumn get avatarUrl => text().nullable().named('avatar_url')();
  TextColumn get publicKey => text().nullable().named('public_key')();
  IntColumn get isActive => integer().withDefault(const Constant(0)).named('is_active')();
  IntColumn get needsSync => integer().withDefault(const Constant(0)).named('needs_sync')();
  TextColumn get createdAt => text().nullable().named('created_at')();

  @override
  Set<Column> get primaryKey => {email};
}
```

- [ ] **Step 2: Actualizar @DriftDatabase annotation**

Cambiar de:
```dart
@DriftDatabase(tables: [Notes, Passwords, SyncQueue, Users, OtpEntries], daos: [NotesDao, PasswordsDao, OtpDao, AuthDao, SyncQueueDao])
```

A:
```dart
@DriftDatabase(tables: [Notes, Passwords, SyncQueue, OfflineUsers, OtpEntries], daos: [NotesDao, PasswordsDao, OtpDao, OfflineAuthDao, SyncQueueDao])
```

- [ ] **Step 3: Actualizar schemaVersion**

Cambiar a 6:
```dart
@override
int get schemaVersion => 6;
```

- [ ] **Step 4: Agregar migración para nueva tabla**

En el método onUpgrade, agregar:
```dart
if (from < 6) {
  await m.createTable(offlineUsers);
}
```

- [ ] **Step 5: Commit**

```bash
cd /Users/joel/Documents/workspace/thisuite/thisjowi/client
git add lib/data/local/database.dart
git commit -m "feat: add OfflineUsers table to drift database"
```

---

## Task 2: Crear OfflineAuthDao

**Files:**
- Create: `lib/data/local/dao/offline_auth.dart`

- [ ] **Step 1: Escribir OfflineAuthDao**

```dart
import 'package:drift/drift.dart';
import '../database.dart';

part 'offline_auth.g.dart';

@DriftAccessor(tables: [OfflineUsers])
class OfflineAuthDao extends DatabaseAccessor<AppDatabase> with _$OfflineAuthDaoMixin {
  OfflineAuthDao(super.db);

  Future<OfflineUser?> getUserByEmail(String email) async {
    return (select(offlineUsers)..where((u) => u.email.equals(email))).getSingleOrNull();
  }

  Future<void> saveUser(OfflineUser user) async {
    await into(offlineUsers).insertOnConflictUpdate(user);
  }

  Future<List<OfflineUser>> getAllUsers() async {
    return await select(offlineUsers).get();
  }

  Future<void> setActiveUser(String email) async {
    await transaction(() async {
      await (update(offlineUsers)..where((u) => u.isActive.equals(1))).write(
        const OfflineUsersCompanion(isActive: Value(0)),
      );
      await (update(offlineUsers)..where((u) => u.email.equals(email))).write(
        const OfflineUsersCompanion(isActive: Value(1)),
      );
    });
  }

  Future<OfflineUser?> getActiveUser() async {
    return (select(offlineUsers)..where((u) => u.isActive.equals(1))).getSingleOrNull();
  }

  Future<int> deleteUser(String email) async {
    return await (delete(offlineUsers)..where((u) => u.email.equals(email))).go();
  }

  Future<bool> isUserLocal(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  Future<void> updatePasswordHash(String email, String hash) async {
    await (update(offlineUsers)..where((u) => u.email.equals(email))).write(
      OfflineUsersCompanion(passwordHash: Value(hash)),
    );
  }

  Future<void> markForSync(String email) async {
    await (update(offlineUsers)..where((u) => u.email.equals(email))).write(
      const OfflineUsersCompanion(needsSync: Value(1)),
    );
  }

  Future<void> clearSyncFlag(String email) async {
    await (update(offlineUsers)..where((u) => u.email.equals(email))).write(
      const OfflineUsersCompanion(needsSync: Value(0)),
    );
  }

  Future<List<OfflineUser>> getUsersNeedingSync() async {
    return (select(offlineUsers)..where((u) => u.needsSync.equals(1))).get();
  }

  Future<void> updateLastLogin(String email) async {
    await (update(offlineUsers)..where((u) => u.email.equals(email))).write(
      OfflineUsersCompanion(lastLogin: Value(DateTime.now().toIso8601String())),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/joel/Documents/workspace/thisuite/thisjowi/client
git add lib/data/local/dao/offline_auth.dart
git commit -m "feat: add OfflineAuthDao for offline authentication"
```

---

## Task 3: Generar código Drift

**Files:**
- Create: `lib/data/local/dao/offline_auth.g.dart` (generated)

- [ ] **Step 1: Ejecutar build_runner**

```bash
cd /Users/joel/Documents/workspace/thisuite/thisjowi/client
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Verificar archivo generado**

Verificar que `offline_auth.g.dart` fue creado con las clases OfflineUser, OfflineUserCompanion, OfflineAuthDao.

- [ ] **Step 3: Commit**

```bash
git add lib/data/local/dao/offline_auth.g.dart lib/data/local/database.g.dart
git commit -m "feat: generate drift code for OfflineAuthDao"
```

---

## Task 4: Crear OfflineAuthService

**Files:**
- Create: `lib/services/offline_auth_service.dart`

- [ ] **Step 1: Escribir OfflineAuthService**

```dart
import 'dart:convert';
import 'package:argon2/argon2.dart';
import 'package:drift/drift.dart';
import 'package:thisjowi/data/local/dao/offline_auth.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/services/crypto_service.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/data/models/auth_user.dart';
import 'package:thisjowi/data/local/database.dart';

class OfflineAuthService {
  static final OfflineAuthService _instance = OfflineAuthService._internal();
  factory OfflineAuthService() => _instance;
  OfflineAuthService._internal();

  final OfflineAuthDao _dao = OfflineAuthDao(AppDatabase.instance());
  final CryptoService _cryptoService = CryptoService();
  final TokenManager _tokenManager = TokenManager();

  Future<String> _hashPassword(String password) async {
    final argon2 = Argon2id(
      memory: 65536,
      iterations: 3,
      parallelism: 4,
      hashLength: 32,
    );
    final hash = await argon2.hashPasswordString(password);
    return hash;
  }

  Future<bool> _verifyPassword(String password, String storedHash) async {
    try {
      final argon2 = Argon2id();
      return await argon2.verifyPasswordString(password, storedHash);
    } catch (e) {
      return false;
    }
  }

  Future<AuthUser?> loginOffline(String email, String password) async {
    final user = await _dao.getUserByEmail(email);
    if (user == null) return null;

    final isValid = await _verifyPassword(password, user.passwordHash);
    if (!isValid) return null;

    await _dao.setActiveUser(email);
    await _dao.updateLastLogin(email);

    await _tokenManager.setUserId(user.id);
    
    final secureStorage = SecureStorageService();
    await secureStorage.saveValue('cached_email', user.email);

    await _cryptoService.initKeys();

    return AuthUser(
      id: user.id,
      email: user.email,
      token: '',
      tokenExpiry: null,
      refreshToken: null,
    );
  }

  Future<AuthUser?> registerOffline({
    required String email,
    required String password,
    String? fullName,
    String? country,
    String? accountType,
    String? hostingMode,
  }) async {
    final existingUser = await _dao.getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('Usuario ya existe');
    }

    final passwordHash = await _hashPassword(password);
    final now = DateTime.now().toIso8601String();

    final user = OfflineUser(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      passwordHash: passwordHash,
      fullName: fullName,
      country: country,
      accountType: accountType,
      hostingMode: hostingMode,
      lastLogin: now,
      avatarUrl: null,
      publicKey: null,
      isActive: 1,
      needsSync: 1,
      createdAt: now,
    );

    await _dao.saveUser(user);
    await _dao.setActiveUser(email);

    await _tokenManager.setUserId(user.id);
    
    final secureStorage = SecureStorageService();
    await secureStorage.saveValue('cached_email', email);

    await _cryptoService.initKeys();

    return AuthUser(
      id: user.id,
      email: user.email,
      token: '',
      tokenExpiry: null,
      refreshToken: null,
    );
  }

  Future<bool> isUserLocal(String email) => _dao.isUserLocal(email);

  Future<List<OfflineUser>> getAllLocalUsers() => _dao.getAllUsers();

  Future<OfflineUser?> getActiveUser() => _dao.getActiveUser();

  Future<void> switchUser(String email, String? password) async {
    final user = await _dao.getUserByEmail(email);
    if (user == null) throw Exception('Usuario no encontrado');

    if (password != null) {
      final isValid = await _verifyPassword(password, user.passwordHash);
      if (!isValid) throw Exception('Contraseña incorrecta');
    }

    await _dao.setActiveUser(email);
    await _dao.updateLastLogin(email);

    await _tokenManager.setUserId(user.id);
    
    final secureStorage = SecureStorageService();
    await secureStorage.saveValue('cached_email', user.email);
  }

  Future<void> deleteLocalUser(String email) async {
    await _dao.deleteUser(email);
  }

  Future<List<OfflineUser>> getUsersNeedingSync() => _dao.getUsersNeedingSync();

  Future<void> clearSyncFlag(String email) => _dao.clearSyncFlag(email);
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/joel/Documents/workspace/thisuite/thisjowi/client
git add lib/services/offline_auth_service.dart
git commit -m "feat: add OfflineAuthService for offline authentication"
```

---

## Task 5: Verificar dependencias

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Verificar package argon2**

Verificar que argon2 está en pubspec.yaml:
```bash
grep argon2 pubspec.yaml
```

Si no existe, agregar:
```yaml
dependencies:
  argon2: ^2.0.0
```

- [ ] **Step 2: Commit**

```bash
git add pubspec.yaml
git commit -m "chore: add argon2 dependency"
```

---

## Execution

**Run all steps and verify:**

```bash
cd /Users/joel/Documents/workspace/thisuite/thisjowi/client

# Task 1 - Modificar database.dart
git add lib/data/local/database.dart
git commit -m "feat: add OfflineUsers table to drift database"

# Task 2 - Crear offline_auth.dart
git add lib/data/local/dao/offline_auth.dart
git commit -m "feat: add OfflineAuthDao for offline authentication"

# Task 3 - Generar código
dart run build_runner build --delete-conflicting-outputs

# Task 4 - Crear servicio
git add lib/services/offline_auth_service.dart
git commit -m "feat: add OfflineAuthService for offline authentication"
```