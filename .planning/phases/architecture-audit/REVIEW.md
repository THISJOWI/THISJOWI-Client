---
phase: architecture-audit
reviewed: 2026-05-15T00:00:00Z
depth: deep
files_reviewed: 155
files_reviewed_list:
  - pubspec.yaml
  - pubspec.lock
  - analysis_options.yaml
  - lib/main.dart
  - lib/core/service_locator.dart
  - lib/core/api.dart
  - lib/core/env_loader.dart
  - lib/core/exceptions.dart
  - lib/core/offline_mode_config.dart
  - lib/core/app_theme.dart
  - lib/core/encryption_helper.dart
  - lib/services/base_service.dart
  - lib/services/auth_service.dart
  - lib/services/api_client.dart
  - lib/services/token_manager.dart
  - lib/services/passwordService.dart
  - lib/services/cryptoService.dart
  - lib/services/offline_auth_service.dart
  - lib/services/logoutService.dart
  - lib/services/account_service.dart
  - lib/services/profile_service.dart
  - lib/services/connectivityService.dart
  - lib/services/otpService.dart
  - lib/services/otpApiService.dart
  - lib/services/messageService.dart
  - lib/services/notesService.dart
  - lib/services/biometricService.dart
  - lib/services/autofillService.dart
  - lib/services/platformAutofillService.dart
  - lib/services/autofillSaveHandler.dart
  - lib/services/credentialSharingService.dart
  - lib/services/organizationService.dart
  - lib/services/github_auth_service.dart
  - lib/services/google_auth_service.dart
  - lib/services/ldapAuthService.dart
  - lib/services/samlAuthService.dart
  - lib/data/local/database.dart
  - lib/data/local/database.g.dart
  - lib/data/local/secure_storage_service.dart
  - lib/data/local/dao/auth.dart
  - lib/data/local/dao/auth.g.dart
  - lib/data/local/dao/passwords.dart
  - lib/data/local/dao/passwords.g.dart
  - lib/data/local/dao/notes.dart
  - lib/data/local/dao/notes.g.dart
  - lib/data/local/dao/otp.dart
  - lib/data/local/dao/otp.g.dart
  - lib/data/local/dao/offline_auth.dart
  - lib/data/local/dao/offline_auth.g.dart
  - lib/data/local/dao/syncQueue.dart
  - lib/data/local/dao/syncQueue.g.dart
  - lib/data/models/user.dart
  - lib/data/models/auth_user.dart
  - lib/data/models/account_user.dart
  - lib/data/models/profile_user.dart
  - lib/data/models/password_entry.dart
  - lib/data/models/note_entry.dart
  - lib/data/models/otp_entry.dart
  - lib/data/models/message.dart
  - lib/data/models/organization.dart
  - lib/data/repository/passwordsRepository.dart
  - lib/data/repository/notes_repository.dart
  - lib/data/repository/otp_repository.dart
  - lib/utils/app_logger.dart
  - lib/utils/DialogUtils.dart
  - lib/utils/GlobalActions.dart
  - lib/i18n/translations.dart
  - lib/i18n/translationService.dart
  - lib/i18n/translationExample.dart
  - lib/components/navigation.dart
  - lib/components/error_bar.dart
  - lib/components/biometric_settings.dart
  - lib/components/social_login_button.dart
  - lib/components/deployment_mode_selector.dart
  - lib/components/ldap_user_card.dart
  - lib/components/animations/animated_widgets.dart
  - lib/core/app_colors.dart
  - lib/core/theme_provider.dart
  - lib/core/providers/otp_provider.dart
  - lib/screens/splash/splash.dart
  - lib/screens/auth/loginForm.dart
  - lib/presentation/screens/biometric_auth_screen.dart
  - lib/presentation/screens/biometric_screen.dart
  - lib/presentation/screens/biometric_auth_example.dart
  - lib/presentation/screens/biometric_example_main.dart
  - lib/screens/debug/logs_screen.dart
  - test/widget_test.dart
  - android/app/src/main/AndroidManifest.xml
  - ios/Runner/Info.plist
  - web/index.html
  - .env.example
  - .gitignore
  - SECURITY.md
  - All 29 duplicate " 2.dart" files
findings:
  critical: 5
  warning: 16
  info: 14
  total: 35
status: issues_found
---

# Architecture & Dependency Audit Report

**Reviewed:** 2026-05-15
**Depth:** deep (cross-file analysis, import graph tracing, dependency vulnerability assessment)
**Files Reviewed:** 155 (including all duplicate files and config files)
**Status:** issues_found — 35 findings (5 Critical, 16 Warning, 14 Info)

---

## Summary

This audit examined the full Flutter project at `thisecure/client` across six dimensions: dependency vulnerabilities, architecture concerns, test coverage, code duplication, platform security config, and build configuration. The project is a password/credential manager with offline-first capabilities using Drift for local persistence, multiple authentication methods (email/LDAP/SAML/OAuth), and E2EE via X25519 + AES-GCM.

**Key concerns:**

- **Deprecated SQLite libraries** with "eol" (end-of-life) suffixes in the dependency tree
- **Pervasive singleton abuse** — virtually every service class uses the same `_instance` + `factory` pattern, creating hidden coupling and making testing nearly impossible
- **Critical cryptographic vulnerability** — offline auth salt generation uses `DateTime.now()` instead of `Random.secure()`, making derived keys predictable
- **Nearly zero test coverage** — only 1 test file which tests a counter app, not thisecure
- **29 duplicate source files** with " 2.dart" suffixes in the `lib/` tree representing stale backups
- **No network security configuration** on Android, no CSP on web, no certificate pinning anywhere
- **Minimal lint rules** — only `package:flutter_lints/flutter.yaml` with no custom rules

---

## Critical Issues

### CR-01: Insecure Salt Generation in OfflineAuthService

**File:** `lib/services/offline_auth_service.dart:26-29`
**Issue:** The `_generateSalt()` method uses `DateTime.now().millisecondsSinceEpoch` as a random source for password hashing salt. This is NOT cryptographically random — an attacker who can approximate when a user registered can predict the salt and precompute rainbow tables. A password manager app MUST use proper cryptographic randomness.
**Fix:**

```dart
import 'dart:math';

String _generateSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64.encode(bytes);
}
```

### CR-02: "End of Life" SQLite Dependencies in Dependency Tree

**File:** `pubspec.lock:1413-1435`
**Issue:** Two transitive dependencies carry "eol" (end-of-life) version suffixes indicating they are no longer maintained:

- `sqlcipher_flutter_libs: 0.7.0+eol`
- `sqlite3_flutter_libs: 0.6.0+eol`

These provide the SQLite engine for local data persistence. EOL libraries no longer receive security patches. A flaw in the SQLite engine could compromise ALL locally stored passwords, notes, and OTP secrets.
**Fix:**

```bash
# Check for replacement packages
flutter pub upgrade
# If no upgrade available, consider migrating to:
# - sqflite (official Flutter SQLite plugin)
# - drift with its built-in sqlite3 support
# Evaluate if sqlcipher is still needed vs. using Flutter's built-in encrypt + sqlite
```

### CR-03: Missing Network Security Config on Android

**File:** `android/app/src/main/` (file absent)
**Issue:** No `network_security_config.xml` file exists. Without this, the Android app has no certificate pinning, no cleartext traffic restrictions, and no domain whitelisting. A man-in-the-middle attacker could intercept all API traffic including password and OTP data in transit.
**Fix:** Create `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <!-- Replace with your actual API domain -->
        <domain includeSubdomains="true">api.thisecure.com</domain>
        <pin-set expiration="2027-01-01">
            <pin digest="SHA-256">base64_encoded_pin_here</pin>
            <pin digest="SHA-256">backup_base64_encoded_pin_here</pin>
        </pin-set>
    </domain-config>
</network-security-config>
```

Then reference it in `AndroidManifest.xml`:

```xml
<application android:networkSecurityConfig="@xml/network_security_config">
```

### CR-04: SecureStorageService Uses SharedPreferences — NOT Actually Secure

**File:** `lib/data/local/secure_storage_service.dart:23-59`
**Issue:** Despite being named `SecureStorageService`, this class stores ALL data (including the database encryption key) in `SharedPreferences`, which writes plaintext to an XML file on Android (`/data/data/<app>/shared_prefs/*.xml`) and to `NSUserDefaults` on iOS. This is a serious data exposure risk — the class name implies security but the implementation provides none. Meanwhile, `TokenManager` correctly uses `flutter_secure_storage`. This creates a false sense of security.
**Fix:**

```dart
// Replace SharedPreferences with FlutterSecureStorage throughout
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String> getDatabaseEncryptionKey() async {
    String? key = await _storage.read(key: _encryptionKeyKey);
    if (key == null) {
      key = await _generateEncryptionKey();
      await _storage.write(key: _encryptionKeyKey, value: key);
    }
    return key;
  }
  // ...apply same pattern to all methods
}
```

### CR-05: Missing Content-Security-Policy on Web

**File:** `web/index.html`
**Issue:** The web build has no Content-Security-Policy meta tag or header. Without CSP, the web app is vulnerable to XSS attacks. Since this app handles passwords and sensitive credentials, XSS could exfiltrate all user data.
**Fix:**

```html
<meta
  http-equiv="Content-Security-Policy"
  content="default-src 'self'; 
               script-src 'self' 'wasm-unsafe-eval'; 
               style-src 'self' 'unsafe-inline'; 
               connect-src 'self' https://api.thisecure.com; 
               img-src 'self' data: https:; 
               font-src 'self';"
/>
```

---

## Warnings

### WR-01: Google Sign-in 2 Major Versions Behind

**File:** `pubspec.yaml:40`
**Issue:** `google_sign_in: ^6.2.1` is locked at 6.3.0 while version 7.2.0 is available. The v7 update includes auth security improvements. The constraint `^6.2.1` prevents upgrading without a manual change. Similarly, `app_links` is on 6.x when 7.x is available.
**Fix:**

```yaml
google_sign_in: ^7.2.0 # Update constraint and test OAuth flow
app_links: ^7.0.0
```

### WR-02: Redundant Cryptographic Libraries

**File:** `pubspec.yaml:29-38`
**Issue:** Three cryptography libraries are included simultaneously:

- `crypto: ^3.0.6` (SHA hashing)
- `encrypt: ^5.0.3` (AES encryption)
- `cryptography: ^2.5.0` (X25519, HKDF, AES-GCM)

The `cryptography` package (version 2.9.0 in lock) already includes SHA hashing and AES capabilities. The `encrypt` and `crypto` packages are redundant, increasing the attack surface from three dependency trees instead of one.
**Fix:** Migrate all hashing to `cryptography` package (already used for E2EE), remove `encrypt` and `crypto` from pubspec.yaml. This reduces dependency attack surface by 2/3.

### WR-03: Pervasive Singleton Pattern — Almost Every Service is a Singleton

**Files:** `lib/services/auth_service.dart:17-19`, `lib/services/api_client.dart:14-16`, `lib/services/token_manager.dart:11-13`, `lib/services/cryptoService.dart:12-14`, `lib/services/offline_auth_service.dart:12-13`, `lib/services/logoutService.dart:14-15`, `lib/services/profile_service.dart:14-15`, `lib/services/connectivityService.dart:6-7`, `lib/data/local/secure_storage_service.dart:15-16`, `lib/core/service_locator.dart:12`
**Issue:** 10 out of ~15 service classes use the exact same singleton pattern:

```dart
static final X _instance = X._internal();
factory X() => _instance;
X._internal();
```

This pattern prevents:

- Unit testing (can't reset/mock singletons between tests)
- Dependency injection (can't swap implementations)
- Proper lifecycle management (can't dispose and recreate)
- Parallel execution in test suites (shared mutable state)

**Fix:** Use a proper DI approach. With Provider already in the dependency list, services should be provided via `ChangeNotifierProvider` or a `ProxyProvider` chain in the widget tree, not hardcoded singletons. Alternatively, use `get_it` for a service locator that supports unregistration for testing.

### WR-04: AccountService Breaks Singleton Pattern Inconsistently

**File:** `lib/services/account_service.dart:7-8`
**Issue:** Every other service in the codebase uses the singleton pattern, but `AccountService` does not:

```dart
class AccountService extends BaseService {
  AccountService() : super('AccountService');  // No singleton!
```

This creates inconsistency — callers may create multiple `AccountService` instances, each with their own `ApiClient` and `TokenManager` (which ARE singletons). This is a logic error that could lead to inconsistent token state.
**Fix:** Either add the singleton pattern (consistent with rest of codebase) or remove the singleton pattern from all services and implement proper DI. Pick one approach.

### WR-05: PasswordService Bypasses BaseService/ApiClient Pattern

**File:** `lib/services/passwordService.dart`
**Issue:** `PasswordService` does NOT extend `BaseService` and uses raw `http.get`/`http.post` instead of the centralized `ApiClient`. This means:

- No request logging
- No timeout management
- No base URL from `ApiConfig` (uses `ApiConfig.passwordsUrl` directly, but no auth header handling via `ApiClient`)
- Token handling is duplicated (lines 21-27 repeat logic already in `ApiClient._authHeaders`)
- Error handling uses return-map pattern (`{success: bool}`) instead of exceptions, inconsistent with all other services

**Fix:** Refactor `PasswordService` to extend `BaseService` and use `apiClient.get/post/etc` like all other services.

### WR-06: BaseService Creates Duplicate Instances of Singletons

**File:** `lib/services/base_service.dart:12-13`
**Issue:**

```dart
final ApiClient _apiClient = ApiClient();
final TokenManager _tokenManager = TokenManager();
```

Since `ApiClient` and `TokenManager` are singletons, `ApiClient()` returns the shared instance. However, `BaseService` holds its own references. Each service extending `BaseService` gets copies of these references. This works by accident (because the singletons share global state), but is conceptually wrong — it implies each service has its own client when it doesn't.
**Fix:** Either remove the field and access via `ApiClient()` directly in methods, or rename to `get apiClient => ApiClient()` to make the singleton access explicit.

### WR-07: Empty Catch Blocks Swallowing Errors

**File:** `lib/services/cryptoService.dart:29-30, 37-42, 71-73, 87-92, 118-119`
**Issue:** Multiple `catch (e) {}` blocks silently swallow errors:

```dart
try {
  final val = await _storage.read(key: key);
  if (val != null) return val;
} catch (e) {
  // Falls through to SharedPreferences fallback silently
}
```

While the fallback-to-SharedPreferences pattern is intentional, silently catching ALL exceptions masks critical errors like storage corruption. A `FlutterSecureStorage` failure on iOS (e.g., keychain access denied) should at minimum be logged at WARNING level, not silently ignored.
**Fix:** Add logging at minimum:

```dart
} catch (e) {
  logWarning('Secure storage failed, falling back to SharedPreferences', error: e);
}
```

### WR-08: Debug print() Calls in Production Code

**Files:** `lib/services/passwordService.dart:227`, `lib/services/logoutService.dart:54-56`, `lib/services/connectivityService.dart:26`
**Issue:** Production code contains `print()` statements that would leak debug information to console in release builds:

- `print('Failed to sync with autofill: $e')` (PasswordService:227)
- `print('✅ Logout completed successfully')` (LogoutService:54)
- `print('⚠️ Error during logout: $e')` (LogoutService:56)
- `print('Couldn\'t check connectivity status: $e')` (ConnectivityService:26)

These should use the AppLogger system or be removed from release builds. `print()` output is visible in logcat on Android and can expose error details including file paths and server information.
**Fix:** Replace `print()` with `appLog.w()`/`appLog.e()` calls that respect the logging configuration.

### WR-09: Empty Logging Stubs in ApiClient

**File:** `lib/services/api_client.dart:255-260`
**Issue:** Both `_logRequest()` and `_logResponse()` methods are completely empty:

```dart
void _logRequest(String method, String url, Map<String, String> headers, [String? body]) {}
void _logResponse(String method, String url, http.Response? response, [String? message]) {}
```

These are called on every single API request (get/post/put/delete/patch/uploadFile) but produce no output. This is dead code that adds cognitive overhead. Either implement logging or remove the calls.
**Fix:** Either implement logging with AppLogger, or remove the method calls from all HTTP methods. The `BaseService.logHttpRequest`/`logHttpResponse` methods exist but aren't being used by ApiClient.

### WR-10: Overly Loose Dependency Constraint — provider: ^6.0.0

**File:** `pubspec.yaml:19`
**Issue:** `provider: ^6.0.0` allows any 6.x version. The resolved version is 6.1.5+1. While this is currently safe, `^6.0.0` theoretically allows 6.999.0 which could introduce breaking changes. Provider is a core dependency used throughout the app.
**Fix:**

```yaml
provider: ^6.1.0 # Pin to known-good minor version
```

### WR-11: rename Package as Direct Main Dependency

**File:** `pubspec.yaml:16`
**Issue:** `rename: ^3.1.0` is a build-time utility for renaming the app package and should be a `dev_dependency`, not a runtime dependency. It gets bundled into the production app unnecessarily.
**Fix:**

```yaml
# Move from dependencies to dev_dependencies:
dev_dependencies:
  rename: ^3.1.0
```

### WR-12: Mixed Error Handling Paradigm Across Services

**Files:** `lib/services/auth_service.dart` vs `lib/services/passwordService.dart`
**Issue:** The codebase has two competing error handling approaches:

1. **Exception-based** (AuthService, ProfileService, AccountService): throw typed exceptions (`AuthException`, `ProfileException`, etc.)
2. **Return-map-based** (PasswordService): return `{success: bool, message: String, data: List}`

Callers must handle both patterns, leading to inconsistent error handling. PasswordService errors are silently ignored if callers expect exceptions.
**Fix:** Standardize on exception-based error handling across all services. The `BaseService.validateResponse()` pattern should be the single approach.

### WR-13: Large Monolithic Service Files

**Files:** `lib/services/auth_service.dart` (524 lines), `lib/services/ldapAuthService.dart` (520 lines), `lib/services/profile_service.dart` (389 lines)
**Issue:** Several service files exceed 300+ lines with multiple responsibilities. `AuthService` handles login, registration, LDAP login, SAML login, token refresh, token validation, and user retrieval — this is at least 3-4 separate concerns. `ProfileService` handles profile CRUD, avatar upload, public key management, and user search.
**Fix:** Split into focused services:

- `AuthService` → `LoginService`, `RegistrationService`, `TokenService`
- `ProfileService` → `ProfileService`, `AvatarService`, `PublicKeyService`

### WR-14: Snapshot-based user ID Generation in OfflineAuthService

**File:** `lib/services/offline_auth_service.dart:102`
**Issue:** Offline users get IDs derived from timestamps:

```dart
id: '${DateTime.now().millisecondsSinceEpoch}',
```

This is non-deterministic on different devices (two devices syncing the same offline user would get different IDs) and can collide in test environments. The `uuid` package is already a direct dependency but isn't used here.
**Fix:**

```dart
import 'package:uuid/uuid.dart';
// ...
id: const Uuid().v4(),
```

### WR-15: AppLogger Factory Pattern Ignores Name Parameter

**File:** `lib/utils/app_logger.dart:287-290`
**Issue:** The `AppLogger` factory constructor ignores the `name` parameter:

```dart
factory AppLogger(String name) {
  _instance ??= AppLogger._internal();
  return _instance!;
}
```

All log entries get the default name "App" unless `name:` is explicitly passed to each log call. The `BaseService` passes a service name to the constructor, but that name is silently discarded.
**Fix:**

```dart
factory AppLogger(String name) {
  _instance ??= AppLogger._internal();
  _instance!._defaultName = name;
  return _instance!;
}
// And in _log():
final loggerName = name ?? _defaultName ?? 'App';
```

### WR-16: Autofill Service Exported Without Restriction

**File:** `android/app/src/main/AndroidManifest.xml:45-55`
**Issue:** The autofill service is exported with only `BIND_AUTOFILL_SERVICE` permission. While this is correct for autofill functionality, there is no `android:permission` restriction on source packages. Any autofill-capable app can query credentials from this service even if they're not the legitimate thisecure app.
**Fix:** The `android:permission="android.permission.BIND_AUTOFILL_SERVICE"` is already present, which is the correct restriction for autofill services. This is **documented but fine** — adding a note that this is by design since autofill services inherently expose data to the system.

---

## Info

### IN-01: 29 Duplicate Source Files in lib/ Tree

**Files:** 29 files with ` 2.dart` suffix
**Issue:** These are stale backup copies created during refactoring or auto-save. They bloat the codebase, confuse import resolution, and could be accidentally imported. Files include: `base_service 2.dart`, `api_client 2.dart`, `token_manager 2.dart`, `profile_service 2.dart`, all model files ` 2.dart`, exception files ` 2.dart`, and screen files ` 2.dart`.
**Fix:**

```bash
find lib -name '* 2.dart' -delete
# Then verify no broken imports: flutter analyze
```

### IN-02: Stale Plugin Lock Files in Project Root

**Files:** `.flutter-plugins-dependencies 2` through `.flutter-plugins-dependencies 6` (5 stale copies)
**Issue:** Five backup copies of `.flutter-plugins-dependencies` exist with different timestamps and contents, totaling ~90KB of stale configuration data.
**Fix:**

```bash
rm '.flutter-plugins-dependencies 2' '.flutter-plugins-dependencies 3' \
   '.flutter-plugins-dependencies 4' '.flutter-plugins-dependencies 5' \
   '.flutter-plugins-dependencies 6'
```

### IN-03: Minimal Lint Rules in analysis_options.yaml

**File:** `analysis_options.yaml`
**Issue:** Only `include: package:flutter_lints/flutter.yaml` is specified. No custom rules for:

- `avoid_print: true`
- `unawaited_futures: true`
- `always_declare_return_types: true`
- `prefer_const_constructors: true`
- `require_trailing_commas: true`
- `no_leading_underscores_for_local_identifiers: true`

**Fix:**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - avoid_print
    - unawaited_futures
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - require_trailing_commas
    - always_declare_return_types
    - avoid_catches_without_on_clauses
    - cancel_subscriptions
    - close_sinks
    - use_build_context_synchronously

analyzer:
  errors:
    missing_return: error
    dead_code: warning
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

### IN-04: Only One Test File — Placeholder Counter Test

**File:** `test/widget_test.dart`
**Issue:** The sole test file tests a "Counter increments smoke test" looking for text '0' and '1' with an `Icons.add` button — this is the default Flutter starter app template, not thisecure. Zero tests exist for:

- Any service class (AuthService, CryptoService, TokenManager, etc.)
- Any model serialization/deserialization
- Any repository data operations
- Any widget/screen rendering
- Any offline/online sync logic

**Fix:** Add minimum test coverage:

```
test/
  services/
    auth_service_test.dart
    crypto_service_test.dart
    token_manager_test.dart
  models/
    user_test.dart
    auth_user_test.dart
    password_entry_test.dart
  repositories/
    passwords_repository_test.dart
  widgets/
    login_screen_test.dart
```

### IN-05: Duplicate Root-Level Backup Files

**Files:** `session-ses_244b 2.md`, `skills-lock 2.json`, `temp_ns 2.json`
**Issue:** These are stale session artifacts that serve no purpose in the repository.
**Fix:**

```bash
rm 'session-ses_244b 2.md' 'skills-lock 2.json' 'temp_ns 2.json'
```

### IN-06: .env Bundled in App Assets — Extractable from APK/IPA

**File:** `pubspec.yaml:68` and `.gitignore:46`
**Issue:** While `.env` is correctly in `.gitignore`, line 68 of `pubspec.yaml` includes `.env` in the Flutter assets bundle. This means the `.env` file is compiled into the APK/IPA and extractable by anyone who decompiles the app. The file contains `LOCAL_NETWORK_IP`, service URLs, and the `REQUEST_TIMEOUT` value — not secrets per se, but it exposes internal network topology.
**Fix:** Remove `.env` from assets and load configuration at build time using `--dart-define` or a configuration service:

```yaml
# Remove this line:
#   - .env
# Instead use dart-define:
# flutter run --dart-define=LOCAL_NETWORK_IP=192.168.1.100
```

### IN-07: User Model — Dual snake_case/camelCase Fallback Pattern

**File:** `lib/data/models/user.dart:34-57`
**Issue:** Every field in `User.fromJson()` handles both `snake_case` and `camelCase` JSON keys:

```dart
accountType: json['accountType'] ?? json['account_type'],
hostingMode: json['hostingMode'] ?? json['hosting_mode'],
isLdapUser: json['isLdapUser'] ?? json['ldapUser'] ?? json['is_ldap_user'] ?? (ldapUsr != null),
```

This indicates an inconsistent API that sometimes returns snake_case and sometimes camelCase. The fallback logic adds complexity and makes it impossible to know which field is "correct." This pattern is repeated across all models.
**Fix:** Standardize the API to consistently return one format (preferably camelCase for Dart/JS convention) and remove the fallback logic.

### IN-08: Unused Import in Test File

**File:** `test/widget_test.dart:12`
**Issue:** `import 'package:thisecure/presentation/screens/biometric_example_main.dart';` imports a demo/example file that is never used in the test. This suggests the test was copied from somewhere and poorly modified.
**Fix:** Remove the unused import. Actually, replace the entire test file with proper tests.

### IN-09: ServiceLocator — Underutilized Redundancy

**File:** `lib/core/service_locator.dart`
**Issue:** The `ServiceLocator` manages only 3 repository singletons (PasswordsRepository, NotesRepository, OtpRepository) while every service independently manages its own singleton via `static final _instance`. This is a half-implemented pattern — either ServiceLocator should manage ALL services, or services should self-manage and ServiceLocator should be removed.
**Fix:** Choose one pattern. If keeping ServiceLocator, register ALL services there and remove self-managed singletons from service classes. If removing, delete ServiceLocator and let repositories self-manage like services do.

### IN-10: Magic Strings — "cached_email" Key Repeated Across 6 Files

**Files:** `lib/services/auth_service.dart:103`, `lib/services/auth_service.dart:161`, `lib/services/auth_service.dart:217`, `lib/services/auth_service.dart:317`, `lib/services/offline_auth_service.dart:72`, `lib/services/offline_auth_service.dart:123`, `lib/services/logoutService.dart:47`
**Issue:** The string literal `'cached_email'` appears in at least 7 locations across 3 files. A typo in any one of these would cause silent caching failures.
**Fix:** Define as a constant:

```dart
class StorageKeys {
  static const String cachedEmail = 'cached_email';
  static const String cachedToken = 'cached_token';
  static const String userId = 'user_id';
  // ...
}
```

### IN-11: Dead Code — KeyboardEventFix Workaround

**File:** `lib/main.dart:24-75`
**Issue:** The `KeyboardEventFix` widget wraps the entire app to work around a macOS keyboard bug (linked GitHub issue #148604). The issue may already be resolved in Flutter 3.38.4 (the version in pubspec.lock). This widget processes every key event globally, adding unnecessary overhead.
**Fix:** Verify if the linked Flutter issue is still open. If resolved, remove the workaround.

### IN-12: iOS Info.plist — Missing NSFaceIDUsageDescription

**File:** `ios/Runner/Info.plist`
**Issue:** While the app uses biometric authentication (`local_auth` package), the Info.plist has no `NSFaceIDUsageDescription` key. On iOS, biometric auth will crash or show a generic prompt without this. Only TouchID may work without it.
**Fix:** Add to Info.plist:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Authenticate to access your passwords and secure data</string>
```

### IN-13: Dead Code — OfflineModeConfig Constants Unused in Production

**File:** `lib/core/offline_mode_config.dart`
**Issue:** This file defines static const configuration values (`disableAutoSync`, `maxSyncRetries`, `suppressSyncErrors`) but they appear to be used for development toggling rather than production configuration. `suppressSyncErrors: true` is dangerous in production — it would silently hide sync failures from users.
**Fix:** Make these environment-dependent, or ensure `suppressSyncErrors` is `false` in production builds.

### IN-14: Mixed Language in Codebase

**Files:** Multiple service and exception files
**Issue:** Code comments and log messages alternate between English and Spanish inconsistently:

- `'Sesion expirada. Inicia sesion nuevamente.'` (ProfileService)
- `'Error al iniciar registro: $e'` (AuthService)
- `'Failed to parse JSON response'` (BaseService)

This makes the codebase harder to maintain for developers who don't speak both languages.
**Fix:** Standardize on one language for all developer-facing content (code comments, log messages). User-facing strings should use the i18n system (`lib/i18n/translations.dart`).

---

_Reviewed: 2026-05-15T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
