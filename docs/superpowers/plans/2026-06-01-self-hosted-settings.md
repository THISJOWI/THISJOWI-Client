# Self-Hosted URL Configuration in Settings — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a settings UI that lets users switch between Cloud and Self-Hosted hosting mode, input a custom server URL when self-hosted is selected, test the connection before saving, and persist the URL so the app uses it on every launch.

**Architecture:** Leverages existing `ApiConfig._manualBaseUrl` infrastructure (already persists to SharedPreferences), the existing `ProfileService.updateProfileFields(hostingMode:)`, and the existing `_showEditHostingModeDialog()` in SettingScreen. We extend the dialog with a URL field + test-connection button, add a hosting item to the settings list, and add a public getter to ApiConfig.

**Tech Stack:** Flutter/Dart, shared_preferences, http (for connection test), Provider

---

## File Structure

- `lib/core/api.dart` — Add `manualBaseUrl` static getter (1 line)
- `lib/i18n/translations.dart` — Add translation strings (6 entries)
- `lib/screens/settings/SettingScreen.dart` — Add state, hosting list item, modify dialog (the bulk of the work)

---

### Task 1: Add `manualBaseUrl` getter to ApiConfig

**Files:**
- Modify: `lib/core/api.dart:80-89`

- [ ] **Add getter after line 80**

```dart
/// Returns the manually set base URL, if any
static String? get manualBaseUrl => _manualBaseUrl;
```

Insert this right after line 80 (`static String? _manualBaseUrl;`).

- [ ] **Verify no syntax errors**

Run: `dart analyze lib/core/api.dart`
Expected: No errors

- [ ] **Commit**

```bash
git add lib/core/api.dart
git commit -m "feat: add manualBaseUrl getter to ApiConfig"
```

---

### Task 2: Add translation keys for hosting UI

**Files:**
- Modify: `lib/i18n/translations.dart`

- [ ] **Add six new entries after the existing Hosting Mode block (around line 309)**

```dart
{
  "en": "Server URL",
  "es": "URL del servidor",
} +
{
  "en": "Enter your server URL",
  "es": "Ingresa la URL de tu servidor",
} +
{
  "en": "Test Connection",
  "es": "Probar conexión",
} +
{
  "en": "Testing connection...",
  "es": "Probando conexión...",
} +
{
  "en": "Connection successful",
  "es": "Conexión exitosa",
} +
{
  "en": "Connection failed",
  "es": "Conexión fallida",
} +
```

Insert these right after the existing `"en": "Update hosting mode"` block (after the `}` + `{` separator at line 310).

- [ ] **Verify syntax by reading surrounding context**

Run: `dart analyze lib/i18n/translations.dart`
Expected: No errors

- [ ] **Commit**

```bash
git add lib/i18n/translations.dart
git commit -m "feat: add hosting UI translation strings"
```

---

### Task 3: Add `_serverUrl` state and load it in SettingScreen

**Files:**
- Modify: `lib/screens/settings/SettingScreen.dart`

- [ ] **Add `_serverUrl` state variable and `_loadHostingConfig`**

After line 38 (`AuthUser? _currentAuthUser;`), add:
```dart
  String? _serverUrl;
```

Add this method after `_loadCurrentUser()` (after line 71):
```dart
  Future<void> _loadHostingConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('custom_api_url');
    if (mounted) {
      setState(() => _serverUrl = url);
    }
  }
```

- [ ] **Add import for shared_preferences**

Add at the top with the other imports (after line 14):
```dart
import 'package:shared_preferences/shared_preferences.dart';
```

- [ ] **Call `_loadHostingConfig` in `_loadInitialData`**

Modify `_loadInitialData()` (line 49-53):
```dart
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadBiometricStatus(),
      _loadCurrentUser(),
      _loadHostingConfig(),
    ]);
  }
```

- [ ] **Verify**

Run: `dart analyze lib/screens/settings/SettingScreen.dart`
Expected: No errors

- [ ] **Commit**

```bash
git add lib/screens/settings/SettingScreen.dart
git commit -m "feat: add serverUrl state and loading to SettingScreen"
```

---

### Task 4: Add hosting list item to settings build

**Files:**
- Modify: `lib/screens/settings/SettingScreen.dart`

- [ ] **Add hosting item after the Country item**

Find `_buildSettingItem` for Country (around line 1384-1390). After the closing `),` of that block, insert:

```dart

                      // Hosting Mode
                      _buildSettingItem(
                        icon: Icons.dns,
                        title: 'Hosting Mode'.i18n,
                        subtitle: _currentAuthUser?.hostingMode ?? 'Cloud',
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currentAuthUser?.hostingMode ?? 'Cloud',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                            if (_serverUrl != null && _serverUrl!.isNotEmpty)
                              Text(
                                _serverUrl!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        onTap: _showEditHostingModeDialog,
                      ),
```

- [ ] **Verify**

Run: `dart analyze lib/screens/settings/SettingScreen.dart`
Expected: No errors

- [ ] **Commit**

```bash
git add lib/screens/settings/SettingScreen.dart
git commit -m "feat: add hosting mode list item to settings"
```

---

### Task 5: Rewrite `_showEditHostingModeDialog` with URL field and test connection

**Files:**
- Modify: `lib/screens/settings/SettingScreen.dart`

- [ ] **Add http import at the top**

After the existing imports (line 14):
```dart
import 'package:http/http.dart' as http;
```

- [ ] **Replace the entire `_showEditHostingModeDialog` method** (lines 894-980)

Replace with:

```dart
  void _showEditHostingModeDialog() {
    String? hostingMode = _currentAuthUser?.hostingMode ?? 'Cloud';
    final urlController = TextEditingController(text: _serverUrl ?? '');
    bool testing = false;
    String? testResult;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Center(
          child: SizedBox(
            width: 400,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: LiquidGlass.wrap(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hosting Mode'.i18n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ['Cloud', 'Self-Hosted']
                          .map((mode) => RadioListTile<String>(
                                title: Text(
                                  mode,
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface),
                                ),
                                value: mode,
                                groupValue: hostingMode,
                                activeColor: Theme.of(context).colorScheme.primary,
                                onChanged: (value) {
                                  setState(() => hostingMode = value);
                                },
                              ))
                          .toList(),
                    ),
                    if (hostingMode == 'Self-Hosted') ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: TextField(
                          controller: urlController,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Server URL'.i18n,
                            hintText: 'https://mi-servidor.com',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.3),
                            ),
                            labelStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.link,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: testing
                              ? null
                              : () async {
                                  setState(() {
                                    testing = true;
                                    testResult = null;
                                    testSuccess = null;
                                  });
                                  final url = urlController.text.trim();
                                  if (url.isEmpty) {
                                    setState(() {
                                      testing = false;
                                      testResult = 'Enter a server URL';
                                      testSuccess = false;
                                    });
                                    return;
                                  }
                                  try {
                                    final testUrl = url.endsWith('/')
                                        ? '${url}v1/health'
                                        : '$url/v1/health';
                                    final response = await http
                                        .get(Uri.parse(testUrl))
                                        .timeout(const Duration(seconds: 10));
                                    setState(() {
                                      testSuccess =
                                          response.statusCode == 200;
                                      testResult = response.statusCode == 200
                                          ? 'Connection successful'.i18n
                                          : '${'Connection failed'.i18n} (${response.statusCode})';
                                    });
                                  } catch (e) {
                                    setState(() {
                                      testSuccess = false;
                                      testResult =
                                          '${'Connection failed'.i18n}: $e';
                                    });
                                  } finally {
                                    if (context.mounted) {
                                      setState(() => testing = false);
                                    }
                                  }
                                },
                          icon: Icon(
                            testing
                                ? Icons.hourglass_top
                                : Icons.wifi_find,
                            size: 20,
                          ),
                          label: Text(
                            testing
                                ? 'Testing connection...'.i18n
                                : 'Test Connection'.i18n,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      if (testResult != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                testSuccess == true
                                    ? Icons.check_circle
                                    : Icons.error,
                                size: 16,
                                color: testSuccess == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  testResult!,
                                  style: TextStyle(
                                    color: testSuccess == true
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel'.i18n,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (hostingMode == null) return;
                              try {
                                await _profileService.updateProfileFields(
                                  hostingMode: hostingMode,
                                );
                                if (hostingMode == 'Self-Hosted') {
                                  final url = urlController.text.trim();
                                  if (url.isNotEmpty) {
                                    await ApiConfig.saveManualBaseUrl(url);
                                    if (mounted) {
                                      setState(() => _serverUrl = url);
                                    }
                                  }
                                } else {
                                  ApiConfig.clearManualBaseUrl();
                                  if (mounted) {
                                    setState(() => _serverUrl = null);
                                  }
                                }
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ErrorSnackBar.showSuccess(
                                    context, 'Hosting Mode updated'.i18n);
                                await _loadCurrentUser();
                              } catch (e) {
                                if (!context.mounted) return;
                                ErrorSnackBar.show(context, 'Error: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text('Save'.i18n),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                context,
                padding: const EdgeInsets.all(24),
                borderRadius: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
```

- [ ] **Add missing import for ApiConfig**

Check if `api.dart` is imported. If not, add:
```dart
import 'package:thisjowi/core/api.dart';
```

- [ ] **Verify**

Run: `dart analyze lib/screens/settings/SettingScreen.dart`
Expected: No errors

- [ ] **Commit**

```bash
git add lib/screens/settings/SettingScreen.dart
git commit -m "feat: add URL field and connection test to hosting dialog"
```

---

### Task 6: Verify full build

- [ ] **Run analyzer on the whole project**

Run: `dart analyze lib/`
Expected: No errors (or only pre-existing errors unrelated to this change)

- [ ] **Run existing tests**

Run: `flutter test`
Expected: Tests pass
