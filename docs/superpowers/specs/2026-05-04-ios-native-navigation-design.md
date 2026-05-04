# iOS 26 Native Navigation Design

**Date:** 2026-05-04
**Status:** Approved

## Overview

Replace the current `GlassBottomBar` from `liquid_glass_widgets` library with a native iOS 26 style navigation using Flutter's native components (`CupertinoTabBar` + `BackdropFilter`). This achieves an authentic iOS native look while removing the dependency on the external liquid_glass_widgets library for navigation.

## Architecture

### Components

1. **CupertinoTabScaffold** — Main tab scaffold (iOS native)
2. **CupertinoTabBar** — Native bottom tab bar with glass effect
3. **BackdropFilter** — Native blur effect for glass appearance
4. **Floating indicator** — Animated pill that slides between tabs (iOS 26 style)
5. **CupertinoIcons** — SF Symbols for icons

### Data Flow

```
HomeScreen / MessagesScreen / OtpScreen / SettingScreen
        ↓
CupertinoTabScaffold.cupertinoTabBar
        ↓
iOSNativeBottomNav (StatefulWidget)
        ↓
IndexedStack for tab persistence
```

## Implementation Details

### Structure

- Single StatefulWidget: `iOSNativeBottomNav`
- Uses `IndexedStack` to preserve tab state
- Desktop: Falls back to existing `_DesktopLayout`
- Mobile: New iOS 26 native navigation

### Glass Effect (BackdropFilter)

```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
  child: Container(
    color:Colors.white.withOpacity(0.1), // tint overlay
  ),
)
```

### Floating Indicator

- Animated container that slides between selected tab
- Uses `AnimationController` + `Tween` for smooth movement
- Position based on button width and index
- Color: Primary color with 20% opacity

### Icons

Replace all `Icons.*` with `CupertinoIcons.*`:
- `Icons.house_rounded` → `CupertinoIcons.house`
- `Icons.chat_bubble_rounded` → `CupertinoIcons.chat_bubble`
- `Icons.shield_rounded` → `CupertinoIcons.lock_shield`
- `Icons.person_rounded` → `CupertinoIcons.person`
- `Icons.settings_rounded` → `CupertinoIcons.settings`

### Pages

Same as current:
- HomeScreen (index 0)
- MessagesScreen (conditional, business only, index 1)
- OtpScreen (index 2 or 1)
- SettingScreen (index 3 or 2)

## Files Modified

1. `lib/components/navigation.dart` — Replace GlassBottomBar with iOS 26 native navigation

## Dependencies Removed

- Remove `liquid_glass_widgets` import (only for this navigation component)
- Keep other imports as needed

## Testing

- Verify blur effect renders correctly
- Verify indicator animates smoothly between tabs
- Verify CupertinoIcons display properly
- Verify haptic feedback on tap
- Verify desktop layout unchanged
- Verify business account conditional tabs work

## Success Criteria

- [ ] Glass effect visible on bottom navigation
- [ ] Floating indicator slides between tabs with animation
- [ ] CupertinoIcons rendering correctly
- [ ] Haptic feedback on tab selection
- [ ] No crashes on tab switching
- [ ] Desktop layout unchanged from current behavior