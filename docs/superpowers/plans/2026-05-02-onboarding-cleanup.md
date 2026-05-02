# Onboarding Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove redundant data collection between onboarding and registration flows. Onboarding handles system configuration; registration handles user data collection.

**Architecture:** Simplify onboarding by removing server URL and country selection pages. These will be handled in registration form instead. The registration form will receive account type and hosting mode from the onboarding flow to determine which conditional fields to show.

**Tech Stack:** Flutter/Dart, Dart null safety

---

## File Structure

- Modify: `lib/screens/onboarding/onBoarding.dart` - Remove server config and map prompt pages, simplify navigation
- Modify: `lib/screens/auth/registerForm.dart` - Simplify conditional field logic based on account type and hosting mode
- Modify: `lib/screens/auth/register_flow.dart` - May need minor adjustments for flow changes
- Create: `docs/superpowers/plans/2026-05-02-onboarding-cleanup.md` - This plan (already created)

---

### Task 1: Update OnboardingScreen - Remove Server Config and Map Prompt Pages

**Files:**
- Modify: `lib/screens/onboarding/onBoarding.dart`

- [ ] **Step 1: Read the current onBoarding.dart to identify exact lines to remove**

Read `lib/screens/onboarding/onBoarding.dart` to find:
- The `_buildServerConfigPage()` method (lines ~587-687)
- The `_buildMapPromptPage()` method (lines ~1000-1091)
- The `_buildLdapConfigPage()` method (lines ~766-950) - this should also be removed
- The controllers that need removal: `_urlController`, all LDAP controllers

- [ ] **Step 2: Remove `_buildServerConfigPage()` method**

Delete the entire `_buildServerConfigPage()` method from the file.

- [ ] **Step 3: Remove `_buildMapPromptPage()` method**

Delete the entire `_buildMapPromptPage()` method from the file.

- [ ] **Step 4: Remove `_buildLdapConfigPage()` method**

Delete the entire `_buildLdapConfigPage()` method from the file.

- [ ] **Step 5: Remove unused controllers from state**

In the state class, remove these controller declarations:
- `_urlController` (line ~33)
- `_ldapServerController` (line ~36)
- `_ldapBaseDnController` (line ~37)
- `_ldapBindDnController` (line ~38)
- `_ldapPasswordController` (line ~39)
- `_userSearchFilterController` (line ~40-41)
- `_emailAttributeController` (line ~42-43)
- `_fullNameAttributeController` (line ~44-45)

- [ ] **Step 6: Remove controller disposal**

In `dispose()` method, remove the dispose calls for all the removed controllers.

- [ ] **Step 7: Update `_buildPages()` method to remove removed page builders**

In `_buildPages()` method (around line ~117-198), update the logic:
- Remove all references to `_buildServerConfigPage()`
- Remove all references to `_buildMapPromptPage()`
- Keep only: intro pages, auth choice, account type, hosting mode
- For Path A (Register): after hosting mode, navigate to registration
- For Path B (Login): after hosting mode, complete onboarding

The updated flow should be:
```
Intro slides (5 pages)
→ Auth Choice (Login/Register)
→ Account Type (Community/Business)
→ Hosting Mode (Cloud/Self-Hosted)
→ [If register] Navigate to registration flow
→ [If login] Complete onboarding → Login
```

- [ ] **Step 8: Test compilation**

Run: `flutter analyze lib/screens/onboarding/onBoarding.dart`
Expected: No errors (may have unused import warnings which is fine)

- [ ] **Step 9: Commit**

```bash
git add lib/screens/onboarding/onBoarding.dart
git commit -m "refactor: remove server config and map prompt from onboarding"
```

---

### Task 2: Update RegisterForm - Simplify Conditional Fields

**Files:**
- Modify: `lib/screens/auth/registerForm.dart`

- [ ] **Step 1: Read registerForm.dart to understand current structure**

The file already handles conditional fields based on accountType and hostingMode:
- `_serverUrlController` - shown only for 'SelfHosted' mode
- `_ldapUrlController` - shown only for 'Business' accountType

- [ ] **Step 2: Verify existing conditional logic is correct**

The current logic already handles:
- Country selector (always shown)
- Server URL (only if hostingMode == 'SelfHosted')
- LDAP URL (only if accountType == 'Business')

This should already work correctly after onboarding changes. The registration form should receive accountType and hostingMode from the register_flow.dart and display appropriate fields.

- [ ] **Step 3: Run flutter analyze to check for issues**

Run: `flutter analyze lib/screens/auth/registerForm.dart`
Expected: No errors

- [ ] **Step 4: Commit if changes needed**

```bash
git add lib/screens/auth/registerForm.dart
git commit -m "refactor: registration form already handles conditional fields correctly"
```

---

### Task 3: Update RegisterFlowScreen - Adjust Navigation

**Files:**
- Modify: `lib/screens/auth/register_flow.dart`

- [ ] **Step 1: Read register_flow.dart to understand current flow**

Current flow:
- Step 0: AccountTypeSelector
- Step 1: DeploymentModeSelector  
- Step 2: LdapSelector (only for Business)
- Step 3: RegisterForm or LdapRegisterForm

- [ ] **Step 2: Verify the registration form receives correct parameters**

The RegisterForm already receives `accountType` and `hostingMode` as parameters. This should work correctly with the simplified onboarding.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze lib/screens/auth/register_flow.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/screens/auth/register_flow.dart
git commit -m "refactor: register flow works with simplified onboarding"
```

---

### Task 4: Integration Test

- [ ] **Step 1: Run full flutter analyze**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 2: Verify navigation works end-to-end**

The flow should now be:
1. Onboarding intro slides → Auth choice → Account type → Hosting mode
2. If login: complete onboarding → Login screen
3. If register: navigate to Registration flow → RegisterForm

- [ ] **Step 3: Final commit**

```bash
git add .
git commit -m "refactor: onboarding cleanup - remove redundant data collection"
```

---

## Summary of Changes

| File | Change |
|------|--------|
| `onBoarding.dart` | Removed `_buildServerConfigPage()`, `_buildMapPromptPage()`, `_buildLdapConfigPage()` and all related controllers. Simplified page flow to: intro slides → auth choice → account type → hosting mode → registration/login |
| `registerForm.dart` | No changes needed - already handles conditional fields based on accountType and hostingMode |
| `register_flow.dart` | No changes needed - already passes accountType and hostingMode to RegisterForm |

---

## Verification Checklist

- [ ] Onboarding no longer asks for server URL (moved to registration)
- [ ] Onboarding no longer asks for country selection (moved to registration)
- [ ] Onboarding no longer asks for LDAP configuration (moved to registration or removed)
- [ ] Registration form shows appropriate fields based on account type and hosting mode
- [ ] All existing functionality preserved (cloud/self-hosted, community/business, LDAP)
- [ ] No duplicate data collection between flows