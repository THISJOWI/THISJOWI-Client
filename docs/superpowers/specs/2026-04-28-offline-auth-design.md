# Diseño: Autenticación Offline-First con DAO

**Fecha:** 2026-04-28
**Proyecto:** thisjowi - Sistema de autenticación offline

---

## Resumen

Permitir registro e inicio de sesión sin conexión a internet usando almacenamiento local SQLite via DAOs de Drift. Sistema hybrid offline-first que prioriza datos locales y sincroniza en background cuando hay conexión.

## Requisitos

1. **Contraseña离线**: solo hash (Argon2id), nunca texto plano
2. **Datos de usuario**: todos los campos (email, nombre, país, tipo de cuenta, etc.)
3. **Sincronización**: automática en background al recuperar conexión
4. **Multi-usuario**: múltiples usuarios locales switchables

---

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                    AuthService                      │
│              (orquesta autenticación)                │
└─────────────────┬───────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
┌───────────────┐   ┌────────────────┐
│ OfflineAuthDao │   │ AuthService    │ (online)
│  (local DB)  │   │  (API calls)  │
└───────────────┘   └────────────────┘
        │
        ▼
┌───────────────┐
│ SyncQueueDao │
│  (cola)    │
└───────────────┘
```

---

## Componentes

### 1. OfflineAuthDao

**Ubicación:** `lib/data/local/dao/offline_auth.dart`

**Tabla:** `offline_users`

| Columna | Tipo | Descripción |
|---------|------|------------|
| id | TEXT | UUID único |
| email | TEXT | Email único |
| password_hash | TEXT | Hash Argon2id |
| full_name | TEXT? | Nombre completo |
| country | TEXT? | País |
| account_type | TEXT? | Tipo de cuenta |
| hosting_mode | TEXT? | Modo de hosting |
| last_login | TEXT? | ISO timestamp |
| avatar_url | TEXT? | URL del avatar |
| public_key | TEXT? | Clave pública E2EE |
| is_active | INTEGER | 1 = usuario activo actual |
| needs_sync | INTEGER | 1 = requiere sync con servidor |

**Métodos:**

```dart
// Buscar usuario por email
Future<OfflineUser?> getUserByEmail(String email);

// Guardar o actualizar usuario
Future<void> saveUser(OfflineUser user);

// Listar todos los usuarios locales
Future<List<OfflineUser>> getAllUsers();

// Marcar usuario como activo
Future<void> setActiveUser(String email);

// Obtener usuario activo actual
Future<OfflineUser?> getActiveUser();

// Eliminar usuario local
Future<void> deleteUser(String email);

// Verificar si existe localmente
Future<bool> isUserLocal(String email);

// Actualizar hash de contraseña
Future<void> updatePasswordHash(String email, String hash);

// Marcar para sincronización
Future<void> markForSync(String email);

// Limpiar marca de sync
Future<void> clearSyncFlag(String email);
```

### 2. OfflineUser (Modelo)

**Ubicación:** `lib/data/models/offline_user.dart`

```dart
class OfflineUser {
  final String id;
  final String email;
  final String passwordHash;
  final String? fullName;
  final String? country;
  final String? accountType;
  final String? hostingMode;
  final String? lastLogin;
  final String? avatarUrl;
  final String? publicKey;
  final bool isActive;
  final bool needsSync;
}
```

---

## Flujos de Usuario

### Login Offline-First

```
1. Usuario ingresa email + password
2. OfflineAuthDao.getUserByEmail(email)
   └── Si existe y hash coincide → login exitoso directo
   └── Si no existe o hash no coincide → goto paso 3
3. AuthService.login() (online)
   └── Si exitoso → OfflineAuthDao.saveUser() → retornar usuario
   └── Si falla (sin internet) → verificar si existe local
   └── Si existe local pero hash no coincide → "Contraseña incorrecta"
   └── Si no existe local → "Sin conexión. Usuario no registrado offline"
```

### Registro Offline

```
1. Usuario ingresa email, password, datos adicionales
2. Generar hash Argon2id de password
3. Crear OfflineUser con needsSync = true
4. OfflineAuthDao.saveUser(user)
5. SyncQueueDao.addOperation('register', user)
6. Retornar usuario ( logged in offline )
7. En background cuando hay conexión → sincronizar con servidor
```

### Cambio de Usuario

```
1. Mostrar dropdown con OfflineAuthDao.getAllUsers()
2. Usuario selecciona nuevo usuario
3. OfflineAuthDao.setActiveUser(email)
4. Si password verificada → login directo
5. Si no verificada → solicitar password
```

### Sincronización Automática

```
1. ConnectivityService detecta cambio a online
2. Para cada usuario con needsSync = true:
   a. AuthService.register() o update
   b. Si exitoso → OfflineAuthDao.clearSyncFlag()
   c. Si falla → mantener needsSync = true
3. Actualizar datos locales con respuesta del servidor
```

---

## Contraseña y Hashing

### Algoritmo

- **Argon2id** (via package `argon2`)
- Parámetros recomendados:
  - Memory: 64 MB (65536 KB)
  - Iterations: 3
  - Parallelism: 4
  - Hash length: 32 bytes

### Almacenamiento

- Solo se almacena el **hash**, nunca la contraseña
- Hash codificado en base64

### Verificación

```dart
Future<bool> verifyPassword(String password, String storedHash) async {
  final argon2 = Argon2id();
  return await argon2.verifyPasswordString(password, storedHash);
}
```

---

## UI para Multi-Usuario

### Pantalla de Login

- **Campo email**: Autocomplete con OfflineAuthDao.getAllUsers()
- **Dropdown usuario**: Para seleccionar de usuarios existentes
- **Modo offline**: Indicador visual cuando no hay conexión
- **Botón cambiar usuario**: Abre selector

### Selector de Usuario

- Lista de usuarios locales con avatar/email
- Indicador de sync status (pendiente/completado)
- Opción "Añadir nuevo usuario"
- Swipe para eliminar

---

## Errores y Edge Cases

| Scenario | Manejo |
|----------|-------|
| Usuario existe online pero no offline | Login online → guardar en local |
| Usuario existe offline pero no online | Login offline directo |
| Contraseña incorrecta offline | "Contraseña incorrecta" |
| Contraseña correcta offline pero servidor cambió datos | Sync al reconectar |
| Usuario borrado en servidor | Eliminar local, solicitar registro nuevo |
| Sync conflicto (datos distintos) | Servidor gana, sobrescribir local |
| Sin conexión + usuario nuevo | Permitir registro offline |
| Sin conexión + login失败 | Error con opción de registro offline |

---

## Dependencias Requeridas

```yaml
dependencies:
  argon2: ^2.0.0
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0

dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.0
```

---

## Archivos a Crear/Modificar

### Nuevos
- `lib/data/local/dao/offline_auth.dart`
- `lib/data/models/offline_user.dart`
- `lib/services/offline_auth_service.dart`
- `lib/data/local/dao/offline_auth.g.dart` (generated)

### Modificar
- `lib/data/local/database.dart` - agregar tabla offline_users
- `lib/services/auth_service.dart` - integrar flujo offline-first
- `lib/screens/auth/loginForm.dart` - UI multi-usuario
- `lib/services/connectivity_service.dart` - auto-sync

---

## Testing

### Unit Tests
- OfflineAuthDao todos los métodos
- Verificación de hash Argon2id
- Flujo login offline exitoso
- Flujo login offline fallido

### Integration Tests
- Login completo offline → online
- Registro offline → sync
- Cambio de usuario

---

## Consideraciones de Seguridad

1. **Hash local**: Argon2id es resistente a GPU/ASIC
2. **No almacenar contraseña plana**: nunca
3. **Secure storage**: usar FlutterSecureStorage para datos sensibles
4. **Biometric unlock**: opcional para mañana
5. **Auto-logout**: después de X tiempo inactivo