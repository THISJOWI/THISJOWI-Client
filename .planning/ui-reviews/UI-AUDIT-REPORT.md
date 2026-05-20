# Flutter UI Audit Report — thisecure Client

**Audited:** 2026-05-15
**Screenshots:** Not captured (no dev server detected at ports 3000, 5173, 8080)
**Methodology:** Code-level audit of all screens, components, and the Liquid Glass design system

---

## Executive Summary

| Area           | Severity     | Key Issue                                                                         |
| -------------- | ------------ | --------------------------------------------------------------------------------- |
| Visual Quality | **HIGH**     | Hardcoded dimensions, inconsistent spacing, mixed theme systems                   |
| Accessibility  | **HIGH**     | Only 9 tooltips in entire app, no Semantics, tiny touch targets                   |
| Responsiveness | **MEDIUM**   | Desktop sidebar good, but mobile layouts use fixed pixel values                   |
| Loading States | **MEDIUM**   | Loading indicators exist but no skeleton screens; settings loads without feedback |
| Error UI       | **CRITICAL** | Success/info notifications are **completely disabled** (commented out)            |
| Liquid Glass   | **CRITICAL** | 89 BackdropFilter instances; severe performance risk on low-end devices           |

---

## 1. Visual Quality Issues

### 1.1 Hardcoded Dimensions (HIGH)

Fixed pixel values that will break on different screen sizes:

| File                    | Line          | Issue                                                             |
| ----------------------- | ------------- | ----------------------------------------------------------------- |
| `navigation.dart`       | 259           | Sidebar `width: 220` — no responsive scaling                      |
| `HomeScreen.dart`       | 743           | FAB `bottom: 130.0` — doesn't account for safe area/notch         |
| `screens/otp/TOPT.dart` | 284           | FAB `bottom: 130.0` (same issue)                                  |
| `PasswordScreen.dart`   | 529           | FAB `bottom: 16.0` (different value!)                             |
| `SettingScreen.dart`    | 139, 247, 433 | Dialogs `width: 400` — overflows on phones <400dp                 |
| `splash.dart`           | 173-174       | Logo `width: 150, height: 150` — fixed size                       |
| `NotesScreen.dart`      | 208-209       | AppBar `expandedHeight: 120, collapsedHeight: 60` — doesn't scale |

**Recommendation:** Replace hardcoded `bottom` on FABs with a value relative to the bottom navigation bar height. Use `ConstrainedBox(maxWidth: min(400, MediaQuery.of(context).size.width - 48))` for dialogs.

### 1.2 Inconsistent Spacing (MEDIUM)

- `HomeScreen` search bar: `blur: 10, opacity: 0.5` — bypasses `LiquidGlass` constants (`subtleBlur: 12, mediumBlur: 20`)
- Item border radius varies: 12 (`PasswordScreen`), 16 (`OtpScreen`), 20 (`HomeScreen`), 25 (search bars)
- `LiquidGlassListItem._buildContent` adds `horizontal: 16, vertical: 12` padding on top of the card's own padding (double-padding)
- `PasswordScreen` item padding: `horizontal: 16, vertical: 12` vs `HomeScreen`: `horizontal: 16, vertical: 16` — inconsistent

**Recommendation:** Establish a spacing/radius scale (8, 12, 16, 20, 24) and enforce through constants. Use LiquidGlass constants consistently — never pass raw numbers for blur/opacity.

### 1.3 Color/Theme Inconsistencies (HIGH)

The app mixes three different color systems:

1. **Material 3 `colorScheme`** from `AppTheme.getDarkTheme()` / `getLightTheme()` (seed: `0xFF2563EB`)
2. **`AppColors` class** (`lib/core/app_colors.dart`) — hardcoded dark colors used directly in `login.dart`
3. **Hardcoded hex colors** in LiquidGlass: `0xFF1C1C1E`, `0xFF2C2C2E`, `0xFF1E1E1E`, `0xFF0A0A0F`

| File                 | Line                        | Problem                                                                         |
| -------------------- | --------------------------- | ------------------------------------------------------------------------------- |
| `liquid_glass.dart`  | 181, 219-220, 460, 465, 478 | Hardcoded hex colors that won't change with theme seed                          |
| `login.dart`         | 317-322                     | Mixes `AppColors.text`, `AppColors.accent` with `Theme.of(context).colorScheme` |
| `error_bar.dart`     | 95-98                       | `Colors.red.shade800/.shade600` — Material swatch colors, not theme-aware       |
| `biometricAuth.dart` | 85, 94, 172, 184, 278       | Hardcoded Spanish strings, not i18n'd                                           |
| `navigation.dart`    | 83-99                       | Tab labels "Home", "Messages", "OTP", "Settings" are NOT i18n'd                 |

**Recommendation:** Eliminate `AppColors` class. Move all colors through `Theme.of(context).colorScheme`. Replace LiquidGlass hardcoded hex values with parameters derived from the theme's `colorScheme`.

### 1.4 Text Overflow Risks (LOW)

- OTP `_formattedCode`: `fontSize: 32, letterSpacing: 4` inside a `Row` with a timer widget — on narrow devices, code may clip. Consider `FittedBox` or reducing font size on small screens.
- Password detail dialog: `entry.title` with `fontSize: 22` in limited space — add `overflow: TextOverflow.ellipsis`.

---

## 2. Accessibility (A11y)

### 2.1 Semantic Labels & Screen Readers (CRITICAL)

| Finding                              | Count                        |
| ------------------------------------ | ---------------------------- |
| Total `tooltip` usages in entire app | **9**                        |
| `Semantics` widget usages            | **0**                        |
| `semanticsLabel` property on icons   | **0**                        |
| `aria-label` equivalents             | **N/A** (not Flutter native) |

**Specific missing labels:**

- All `IconButton`s with `constraints: BoxConstraints()` and `padding: EdgeInsets.zero` — no tooltip (HomeScreen lines 852-877, PasswordScreen lines 208-279, OtpScreen lines 560-567)
- OTP copy action: user is told "Tap to copy" visually but screen reader gets nothing
- Search clear buttons: no `tooltip` on the `IconButton`
- Expandable FAB: no semantic label for "Create" action
- Visibility toggle on password fields: no tooltip (except one case in `SettingScreen.dart:576`)

### 2.2 Contrast Ratios (HIGH)

Multiple text elements use alpha values that fail WCAG AA:

| File                | Line     | Alpha        | Likely Fail WCAG AA?  |
| ------------------- | -------- | ------------ | --------------------- |
| `HomeScreen.dart`   | 768, 773 | 0.7          | Borderline on dark bg |
| `HomeScreen.dart`   | 978      | 0.3          | **YES — fails**       |
| `TOPT.dart`         | 622      | 0.3          | **YES — fails**       |
| `liquid_glass.dart` | 844      | 0.6          | Borderline            |
| `liquid_glass.dart` | 70       | 0.5 (border) | Low visibility        |

The design relies heavily on `withValues(alpha: 0.3-0.6)` for secondary text. For dark backgrounds (`#121212`), alpha 0.5 on white yields approximately 3:1 ratio — failing the 4.5:1 minimum.

### 2.3 Touch Target Sizes (HIGH)

WCAG 2.2 requires minimum 44×44px touch targets:

| File                  | Line(s)                | Issue                                                                                   |
| --------------------- | ---------------------- | --------------------------------------------------------------------------------------- |
| `HomeScreen.dart`     | 511, 556, 570, 868-875 | `constraints: BoxConstraints(), padding: EdgeInsets.zero` → <20px hit area              |
| `PasswordScreen.dart` | 208, 264, 277          | Same pattern — edit/delete/copy icons at 18px                                           |
| `TOPT.dart`           | 560-567                | Delete icon at 20px with no padding                                                     |
| `liquid_glass.dart`   | 848                    | `behavior: HitTestBehavior.opaque` is good, but the `NavigationItem` tap area is narrow |

### 2.4 Keyboard Navigation (MEDIUM)

**Good:** Form fields use FocusNode chaining (`requestFocus()` on submit). Login, register, and LDAP forms chain correctly.

**Missing:**

- No `Shortcuts` / `Actions` widgets anywhere — no keyboard shortcuts for common actions (Enter to submit, Escape to close dialogs)
- Tab navigation between icon-only buttons is not managed
- The `KeyboardEventFix` in `main.dart` only handles a macOS duplicate-key bug — it's not a navigation enhancement

---

## 3. Responsiveness

### 3.1 Desktop Layout (GOOD)

`Navigation` uses `LayoutBuilder` + `width >= 600` to switch to `_DesktopLayout` with a 220px sidebar. This is a solid pattern. The sidebar uses `IndexedStack` to preserve state.

### 3.2 Mobile Layout Issues (HIGH)

| Issue                                      | Files Affected                        |
| ------------------------------------------ | ------------------------------------- |
| FAB positioned at absolute `bottom: 130.0` | HomeScreen, OtpScreen, PasswordScreen |
| Dialogs hardcoded `width: 400`             | SettingScreen, LoginScreen            |
| No `LayoutBuilder` for content width       | HomeScreen, OtpScreen, SettingsScreen |
| ListView bottom padding `150` hardcoded    | HomeScreen, OtpScreen                 |
| No tablet-optimized 2-column grid          | Any data screen                       |

**Specific FAB calculation problem:** The FAB is at `bottom: 130.0` to sit above the bottom nav bar. If the user changes system font scaling (accessibility), the bottom bar height changes but the FAB stays at 130 — overlapping the nav. The correct approach: use `MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16 + fabHeight` or reference the actual navigation bar height.

### 3.3 Scroll Handling (GOOD)

- Login screen: `SingleChildScrollView` handles keyboard overlap. ✓
- Password detail dialogs: `SingleChildScrollView` prevents overflow. ✓

---

## 4. Loading States

### 4.1 Present (ADEQUATE)

| Screen         | Loading Indicator                                     | Quality |
| -------------- | ----------------------------------------------------- | ------- |
| HomeScreen     | `CircularProgressIndicator` in center                 | ✓       |
| OtpScreen      | `CircularProgressIndicator` in center                 | ✓       |
| PasswordScreen | `CircularProgressIndicator` in center                 | ✓       |
| NotesScreen    | `CircularProgressIndicator` via `SliverFillRemaining` | ✓       |
| Login          | Spinner inside button                                 | ✓       |
| AuthSelection  | Spinner below buttons                                 | ✓       |

### 4.2 Missing (MEDIUM)

- **SettingsScreen:** `_loadInitialData()` loads both biometric status and user profile asynchronously but there's **no loading flag**. The screen renders immediately with `null` values, then updates when data arrives. This causes a visible flash of "Not set" for profile fields.
- **No skeleton/shimmer loading:** Despite `skeletonizer: ^2.1.1` being in `pubspec.yaml`, it's never used. Standard `CircularProgressIndicator` provides no content shape preview.
- **Splash screen:** If the auth check takes >2 seconds (animation duration), the user has no progress indication except the spinning circle. No "Checking credentials..." text.

**Recommendation:** Add `_isLoading` to SettingsScreen state. Implement skeleton loading for list screens using the already-installed `skeletonizer` package.

---

## 5. Error UI

### 5.1 CRITICAL: Success/Info Notifications Disabled

In `lib/components/error_bar.dart`, both `showSuccess()` and `showInfo()` have their implementation **commented out**:

```dart
// error_bar.dart:37-49
static void showSuccess(...) {
    // Notifications disabled by user request
    /*
    ScaffoldMessenger.of(context).showSnackBar(...)
    */
}
```

This means:

- When a user copies a password: **no visual feedback**
- When a user deletes a password: **no confirmation of success**
- When a user saves profile changes: **no confirmation**
- When a user copies a username: **no feedback**

The only feedback method that works is `show()` (errors) and `showWarning()` (warnings). Users performing successful actions get **zero acknowledgment**.

### 5.2 Error Messages Contain Technical Details (MEDIUM)

| File                  | Line | Pattern                                                                 |
| --------------------- | ---- | ----------------------------------------------------------------------- |
| `SettingScreen.dart`  | 622  | `'Error changing password: $e'` — exposes exception details             |
| `SettingScreen.dart`  | 664  | `'Error: $e'` — raw exception                                           |
| `SettingScreen.dart`  | 413  | `'Error deleting account: $e'` — raw exception                          |
| `PasswordScreen.dart` | 83   | `result['message'] ?? 'Error loading passwords'` — server error exposed |

### 5.3 Empty Catch Blocks (LOW)

```dart
// NotesScreen.dart:59
} catch (snackBarError) {
    // Nothing — swallow error silently
}
```

Appears in `NotesScreen.dart` (lines 59, 68, 147, 157), `TOPT.dart` (lines 93, 102, 157). If the SnackBar fails to show, the user gets no feedback at all.

### 5.4 Good Patterns

- Warning snackbar (`WarningSnackBar`) has excellent glass-blur visual design with proper contrast.
- Login screen handles specific exception types (`NetworkException`, `AuthException`, etc.)
- `ErrorSnackBar.show()` provides structured container with icon, color accent bar, and message.

---

## 6. Liquid Glass Design System Audit

### 6.1 Performance: Excessive BackdropFilter Usage (CRITICAL)

**89 instances** of `BackdropFilter` / `ImageFilter.blur` across the codebase. Every `BackdropFilter` triggers GPU offscreen rendering of the entire backdrop layer.

| Context                                         | Blur Layers                                                 | Performance Impact                |
| ----------------------------------------------- | ----------------------------------------------------------- | --------------------------------- |
| **SettingsScreen**                              | 1 full-screen blur (sigma:20) + 20+ card blurs              | **SEVERE**                        |
| **Each list item** (HomeScreen, OTP, Passwords) | 1 per item                                                  | Grows linearly with data          |
| **Navigation bar**                              | 1 container blur + 1 per tab + GlassBottomBar blur          | 4-7 layers on screen at all times |
| **Login screen**                                | Full-screen backdrop blur (sigma:50) + card blur (sigma:20) | 2 heavy layers                    |
| **LiquidGlass.container**                       | 1 per call (dozens per screen)                              | Cumulative GPU load               |

**Recommendation:** For static blur effects (settings background), consider pre-rendering a blurred image or using a single `BackdropFilter` at the scaffold level instead of per-item. For lists, use `RepaintBoundary` around each item to avoid repainting. Consider using `Opacity` + solid color instead of `BackdropFilter` for non-critical blur effects.

### 6.2 Animation Performance (HIGH)

- `_MorphingGlassContainer` animates **4 properties simultaneously** (blur, opacity, radius, scale) every frame — blur is the most expensive.
- `_InteractiveGlass` runs both `Transform.scale` AND `AnimatedOpacity` AND `HapticFeedback.lightImpact()` on every tap.
- `_NavigationItem` per-tab animation with `BackdropFilter` — when switching tabs, multiple blur layers animate simultaneously.

### 6.3 Design System Integrity Issues (MEDIUM)

| Issue                                                                                              | Location                                              |
| -------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| `glassEffect()` extension always renders dark mode                                                 | `liquid_glass.dart:952` — no `BuildContext` parameter |
| `LiquidGlass.container` defaults to `Brightness.dark` when context is null                         | `liquid_glass.dart:54`                                |
| `LiquidGlassListItem` uses `opacity: mediumOpacity * 2.0`                                          | `liquid_glass.dart:889` — bypassing design scale      |
| Inconsistent blur values: screens use `blur: 10` directly instead of `LiquidGlass.subtleBlur (12)` | All data screens                                      |
| `GlassEffectContainer` duplicates the glass rendering logic of `LiquidGlass.container`             | Two parallel implementations                          |

**Recommendation:** Make `context` required on `LiquidGlass.container`. Deprecate the glassEffect extension until it accepts context. Audit all screens and replace raw blur/opacity values with LiquidGlass constants.

### 6.4 Memory (MEDIUM)

- Each `_OtpCard` creates its own `Timer.periodic(seconds: 1)` — with 20 OTP entries, that's 20 timers firing every second.
- `_LiquidGlassNavigationBarState` holds `List<AnimationController>` that are only disposed on widget teardown.

---

## Summary of Critical Findings

| #   | Severity     | Finding                                                                  | Fix                                                                              |
| --- | ------------ | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| 1   | **CRITICAL** | Success/info notifications entirely disabled                             | Re-enable `showSuccess()` and `showInfo()` in `error_bar.dart`                   |
| 2   | **CRITICAL** | 89 BackdropFilter instances causing GPU thrash                           | Single top-level blur + conditional per-item blur. Use `RepaintBoundary`.        |
| 3   | **HIGH**     | No semantic labels or screen reader support                              | Add `tooltip` to all `IconButton`s. Add `Semantics` wrappers for custom widgets. |
| 4   | **HIGH**     | FAB positioned at absolute `bottom: 130.0` — breaks on different devices | Use `MediaQuery.of(context).padding.bottom + navBarHeight + 16`                  |
| 5   | **HIGH**     | Touch targets <20px on edit/delete/copy buttons                          | Set minimum 44×44 constraints on all interactive icons                           |
| 6   | **HIGH**     | SettingsScreen has no loading state                                      | Add `_isLoading` flag to `_SettingScreenState`                                   |
| 7   | **HIGH**     | Three competing color systems (M3, AppColors, hardcoded hex)             | Consolidate to `Theme.of(context).colorScheme` only                              |
| 8   | **MEDIUM**   | Dialogs hardcoded `width: 400` overflow on phones                        | Use `ConstrainedBox` with `maxWidth: MediaQuery.of(context).size.width - 48`     |
| 9   | **MEDIUM**   | Tab labels not i18n'd ("Home", "Messages", etc.)                         | Use `.i18n` / `.tr(context)` like the rest of the app                            |
| 10  | **MEDIUM**   | BiometricAuth screen hardcoded Spanish strings                           | Use i18n translations                                                            |

---

## Files Audited

- `lib/main.dart`
- `lib/core/app_theme.dart`
- `lib/core/app_colors.dart`
- `lib/components/liquid_glass.dart` (full)
- `lib/components/error_bar.dart` (full)
- `lib/components/button.dart` (ExpandableActionButton)
- `lib/components/navigation.dart` (full)
- `lib/components/privacy_overlay.dart`
- `lib/screens/splash/splash.dart`
- `lib/screens/auth/login.dart`
- `lib/screens/auth/authSelection.dart`
- `lib/screens/auth/biometricAuth.dart`
- `lib/screens/home/HomeScreen.dart` (full)
- `lib/screens/otp/TOPT.dart` (full)
- `lib/screens/settings/SettingScreen.dart` (full)
- `lib/screens/password/PasswordScreen.dart` (full)
- `lib/screens/notes/NotesScreen.dart` (full)
