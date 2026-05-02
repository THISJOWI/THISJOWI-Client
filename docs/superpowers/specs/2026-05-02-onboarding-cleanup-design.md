# Onboarding Flow Cleanup Design

## Overview
Remove redundant data collection between onboarding and registration flows. Onboarding will focus on system configuration while registration focuses on user data collection.

## Problem
- Onboarding collects: account type, hosting mode, LDAP setup, server URL, country
- Registration collects: name, email, password, country, server URL, LDAP URL
- Significant overlap causing duplicate data collection

## Solution
- **Onboarding**: Pure configuration (account type, hosting mode, LDAP setup)
- **Registration**: Pure user data (name, email, password, country, server/LDAP config)

## Onboarding Flow Changes

### Pages to KEEP:
- Pages 0-4: Intro slides + auth choice
- Account type selection (Community/Business)
- Hosting mode selection (Cloud/Self-Hosted)
- LDAP setup (only for Business accounts)

### Pages to REMOVE:
- `_buildServerConfigPage()` - Server URL config moved to registration
- `_buildMapPromptPage()` - Country selection moved to registration
- All LDAP configuration pages (moved to registration or removed)

### Navigation Changes:
- After completing config, navigate directly to registration flow
- Remove `_urlController` and related LDAP controllers

## Registration Flow Changes

### Fields to KEEP:
- Name (full name)
- Email
- Password
- Country (always)
- Server URL (only if self-hosted)
- LDAP URL (only if business + LDAP enabled)

### Validation Updates:
- Server URL validation only for self-hosted mode
- LDAP URL validation only for business accounts with LDAP enabled

## Data Flow

```
Onboarding (Config) → Registration (User Data)
├─ Account Type → Determines LDAP field requirement
├─ Hosting Mode → Determines server URL field requirement
└─ LDAP Choice → Determines LDAP field visibility
```

## Implementation Files

1. `lib/screens/onboarding/onBoarding.dart`
   - Remove `_buildServerConfigPage()`
   - Remove `_buildMapPromptPage()`
   - Remove LDAP config page
   - Simplify page flow logic
   - Remove unused controllers (_urlController, LDAP controllers)

2. `lib/screens/auth/registerForm.dart`
   - Keep server URL field (only for self-hosted)
   - Keep LDAP URL field (only for business + LDAP)
   - Update conditional field logic

3. `lib/screens/auth/register_flow.dart`
   - May need minor adjustments for flow changes

## Success Criteria
- No duplicate data collection between flows
- Clear separation of system setup vs user account creation
- Minimal impact on existing user flows
- All functionality preserved (cloud/self-hosted, community/business, LDAP)