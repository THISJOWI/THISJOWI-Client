# Self-Hosted URL Configuration in Settings

## Problem
Users cannot configure a custom server URL from the settings screen. While the registration flow supports self-hosted server URL input, once the account is created there's no way to change the hosting mode or update the server URL.

## Goal
Add a settings UI that lets users switch between Cloud (community) and Self-Hosted mode, input a custom server URL when self-hosted is selected, test the connection, and persist the URL so the app always uses it.

## Design

### Settings list item
- Add a new item titled "Hosting" in the settings list, placed after Country and before LDAP Configuration
- Shows: `Cloud` or `Self-Hosted` as subtitle
- If Self-Hosted, also shows the server URL as secondary subtitle
- Tap opens the hosting mode dialog

### Hosting mode dialog
- Radio buttons: "Cloud" and "Self-Hosted"
- When "Self-Hosted" is selected, a text field appears for server URL (e.g., `https://mi-servidor.com`)
- The field is pre-filled with the previously saved URL if any
- A "Test Connection" button that sends a GET to `${serverUrl}/v1/health` and shows success/failure
- A "Save" button that:
  - Saves `hostingMode` to the user profile via `ProfileService.updateProfileFields()`
  - Persists the server URL locally via `ApiConfig.saveManualBaseUrl()`
  - If switching to Cloud, calls `ApiConfig.clearManualBaseUrl()`

### On app start
- Already handled by `ApiConfig.init()` in `main.dart` which loads from SharedPreferences

### Files to modify
- `lib/screens/settings/SettingScreen.dart`:
  - Add hosting item to the build list
  - Add `_serverUrl` state variable, load from `ApiConfig` or prefs
  - Modify `_showEditHostingModeDialog()` to include URL field + test connection
- `lib/i18n/translations.dart`: Add necessary translation keys

### Connection test
- Simple GET to `${serverUrl}/v1/health` (same health endpoint the API already uses)
- Show success/error feedback inline in the dialog

### Data flow
```
Settings → Dialog → User selects Self-Hosted → Enters URL → Test → Save
  ├─ ProfileService.updateProfileFields(hostingMode: "SelfHosted")
  ├─ ApiConfig.saveManualBaseUrl(url) → SharedPreferences
  └─ ApiConfig.setManualBaseUrl(url) → applied immediately

On app restart:
  main.dart → ApiConfig.init() → loads from SharedPreferences → baseUrl uses manual URL
```
