# iOS Autofill — Shared Keychain Design

**Date:** 2026-06-02
**Status:** Approved
**Platform:** iOS (CredentialProviderExtension + main app via Flutter)

---

## Motivation

The iOS credential provider extension (`ios/CredentialProviderExtension/`) currently reads from an empty `UserDefaults(suiteName:)`, so it never has passwords to offer. The main app has no mechanism to share credential data with the extension. This spec fixes all iOS autofill infrastructure.

---

## Current Problems

| # | Severity | Problem |
|---|----------|---------|
| P1 | Critical | AppDelegate.swift has no method channel handler for `com.thisjowi/credentials` |
| P2 | Critical | Main app entitlements (`ios/Runner/`) missing `com.apple.security.application-groups` — cannot write to shared container |
| P3 | Critical | Real extension (`CredentialProviderExtension/`) reads from empty UserDefaults |
| P4 | High | Duplicate stub extension (`ios/THISECURE/CredentialProviderViewController.swift`) with hardcoded credentials |
| P5 | High | Extension's `prepareCredentialList` cancels instead of showing credential list |
| P6 | High | `ASCredentialIdentityStore` never populated — no QuickType credentials |
| P7 | Low | `CredentialSharingService` exists in Dart but is never invoked |

---

## Architecture

```
┌──────────────────────────────┐     ┌──────────────────────────────┐
│    Main App (Flutter)        │     │  CredentialProviderExtension  │
│                              │     │                              │
│  CredentialSharingService    │     │  CredentialProviderViewCtrl   │
│  (Dart - method channel)     │     │  (native Swift)              │
│         │                    │     │         ▲                    │
│         ▼                    │     │         │                    │
│  AppDelegate.swift           │     │         │                    │
│  (native handler)            │     │         │                    │
│         │                    │     │         │                    │
│         ▼                    │     │         │                    │
│  ┌─────────────────────┐     │     │  ┌─────────────────────┐    │
│  │ CredentialKeychain  │◄────┼─────┼──┤ CredentialKeychain  │    │
│  │ Service (shared)    │     │     │  │ Service (shared)    │    │
│  └─────────┬───────────┘     │     │  └─────────────────────┘    │
│            │                 │     │                              │
│            ▼                 │     │                              │
│  ┌──────────────────┐       │     │                              │
│  │ Shared Keychain  │       │     │                              │
│  │ (App Group)      │       │     │                              │
│  └──────────────────┘       │     │                              │
│            │                 │     │                              │
│            ▼                 │     │                              │
│  ASCredentialIdentityStore   │     │                              │
│  (QuickType bar)             │     │                              │
└──────────────────────────────┘     └──────────────────────────────┘
```

**Keychain Access Group:** `$(AppIdentifierPrefix)group.com.thisjowi.thisecure`

Both targets share the same App Group `group.com.thisjowi.thisecure`, which allows Keychain sharing via `kSecAttrAccessGroup`.

---

## Data Model

A single Keychain entry with:

- **Key:** `"com.thisjowi.shared.credentials"`
- **Value:** JSON-encoded array of credential objects

```json
[
  {
    "id": "uuid-string",
    "title": "Twitter",
    "username": "user@example.com",
    "password": "secret123",
    "website": "twitter.com"
  }
]
```

---

## Flows

### 1. Save Credential (main app → extension)

1. User saves/updates/deletes a password in Flutter UI
2. Dart calls `CredentialSharingService.syncPasswordsToSharedStorage()`
3. Method channel `com.thisjowi/credentials → syncPasswordsToAppGroup` invoked
4. AppDelegate handler receives credential list as JSON
5. Writes to shared Keychain via `CredentialKeychainService.saveCredentials()`
6. Calls `ASCredentialIdentityStore.shared.saveCredentialIdentities()` with each credential

### 2. AutoFill via QuickType (no UI)

1. User taps password field in app/Safari
2. iOS finds matching `ASCredentialIdentity` in store
3. Shows credential in QuickType bar above keyboard
4. User taps the credential
5. iOS calls extension's `provideCredentialWithoutUserInteraction(for:)`
6. Extension reads `recordIdentifier` from identity
7. Looks up in shared Keychain via `CredentialKeychainService.readCredentials()`
8. Returns `ASPasswordCredential(user:password:)`
9. If credential not found or needs interaction, calls `extensionContext.cancelRequest(withError:)`

### 3. AutoFill via Extension UI

1. User selects "Passwords..." from keyboard autofill menu
2. iOS calls extension's `prepareCredentialList(for:)`
3. Extension reads all credentials from shared Keychain
4. Filters by service identifier URL domain (shows relevant credentials)
5. Renders native UITableView with credential list
6. User taps a credential
7. Extension calls `extensionContext.completeRequest(withSelectedCredential:)`
8. Returns `ASPasswordCredential(user:password:)`

---

## Files to Create / Modify

### New files

- `ios/Shared/CredentialKeychainService.swift` — Shared Keychain read/write (used by both AppDelegate and Extension)

### Modified files

- `ios/Runner/AppDelegate.swift` — Add method channel handler for `com.thisjowi/credentials`
- `ios/Runner/Runner.entitlements` — Add `com.apple.security.application-groups` with `group.com.thisjowi.thisecure`
- `ios/CredentialProviderExtension/CredentialProviderViewController.swift` — Read from Keychain, implement credential list UI
- `lib/services/credentialSharingService.dart` — Wire up to be called from password CRUD operations

### Removed files

- `ios/THISECURE/CredentialProviderViewController.swift` (stub with hardcoded credentials)
- `ios/THISECURE/Info.plist` (extension registration for stale stub)
- `ios/THISECURE/THISECURE.entitlements` (no longer needed)

---

## Keychain Implementation Details

### Saving credentials

```swift
func saveCredentials(_ credentials: [[String: String]]) throws {
    let data = try JSONSerialization.data(withJSONObject: credentials)
    let query: [String: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrAccount: "com.thisjowi.shared.credentials",
        kSecAttrAccessGroup: "\(teamId).group.com.thisjowi.thisecure",
        kSecValueData: data,
        kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    SecItemDelete(query as CFDictionary) // overwrite
    SecItemAdd(query as CFDictionary, nil)
}
```

### Reading credentials

```swift
func readCredentials() throws -> [[String: String]] {
    let query: [String: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrAccount: "com.thisjowi.shared.credentials",
        kSecAttrAccessGroup: "\(teamId).group.com.thisjowi.thisecure",
        kSecReturnData: true
    ]
    var result: CFTypeRef?
    SecItemCopyMatching(query as CFDictionary, &result)
    guard let data = result as? Data else { return [] }
    return try JSONSerialization.jsonObject(with: data) as? [[String: String]] ?? []
}
```

---

## Method Channel Contract (`com.thisjowi/credentials`)

| Method | Args | Returns | Description |
|--------|------|---------|-------------|
| `syncPasswordsToAppGroup` | `{passwords: [json objects], forceRegisterIdentities: bool}` | `Bool` | Writes all passwords to shared Keychain. If `forceRegisterIdentities`, also updates `ASCredentialIdentityStore` |
| `registerCredentialIdentities` | `{passwords: [json objects]}` | `Bool` | Registers all passwords as credential identities in `ASCredentialIdentityStore` |
| `clearCredentialIdentities` | none | `Bool` | Clears both Keychain entry and `ASCredentialIdentityStore` |

---

## Implementation Order

1. **Clean up:** Remove stale `ios/THISECURE/` extension, add App Groups + Keychain access groups to `Runner.entitlements`
2. **AppDelegate:** Add `CredentialKeychainService` class + `com.thisjowi/credentials` method channel handler (syncPasswordsToAppGroup, registerCredentialIdentities, clearCredentialIdentities)
3. **Extension:** Update `CredentialProviderViewController.swift` with embedded `CredentialKeychainService` + credential list UI
4. **Dart sync:** Add `PasswordService().syncWithAutofill()` call in `Navigation._initNavigation()` (CRUD sync already existed in PasswordService)
5. **Xcode:** Add CredentialProviderExtension target to Xcode project (see Xcode Integration section)
6. **Verify:** Save password in app → appears in QuickType → auto-fill works

---

## Xcode Integration

The CredentialProviderExtension target must be added to the Xcode project. The source files exist on disk but the target is not in `project.pbxproj`.

### Steps in Xcode:

1. **Open workspace:** `ios/Runner.xcworkspace` in Xcode
2. **Add extension target:** File → New → Target → Credential Provider Extension
   - Product Name: `CredentialProviderExtension`
   - Bundle Identifier: `com.thisjowi.thisecure.CredentialProviderExtension`
   - Language: Swift
   - Uncheck "Embed in application" (kept as separate target)
3. **Replace generated files:** Xcode generates `CredentialProviderViewController.swift` and `Info.plist`. Delete them from the extension target and instead:
   - Add existing file: `ios/CredentialProviderExtension/CredentialProviderViewController.swift`
   - Add existing file: `ios/CredentialProviderExtension/Info.plist`
   - Add existing file: `ios/CredentialProviderExtension/CredentialProviderExtension.entitlements`
4. **Verify entitlements:** The extension's `Signing & Capabilities` should show App Groups with `group.com.thisjowi.thisecure`
5. **Verify main app entitlements:** Runner target should have both:
   - App Groups: `group.com.thisjowi.thisecure`
   - Keychain Sharing: `$(AppIdentifierPrefix)group.com.thisjowi.thisecure`
6. **Build:** Should compile with no errors
7. **Run on device:** The extension is embedded in the app and can be enabled in Settings → Passwords → AutoFill Passwords → select THISECURE

### Verification:

After setup, test the flow:
1. Run the app on a device
2. Save a password in the app
3. Open Safari and navigate to a site with the same domain
4. Tap a password field → QuickType bar should show the saved credential
5. Select "Passwords..." from keyboard menu → extension UI should list matching credentials

## Out of Scope (for this round)

- Android autofill fix (separate design/plan)
- `platformAutofillService.dart` cleanup (dead code, no functional impact)
- iOS `prepareCredentialList` native UI polish (MVP = list with table view)
- macOS extension updates (same pattern as iOS, defer)
