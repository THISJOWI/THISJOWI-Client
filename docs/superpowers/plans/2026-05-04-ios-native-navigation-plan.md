# iOS 26 Native Navigation Implementation Plan

> **For agentic workers:** Use subagent-driven-development or executing-plans to implement this plan task-by-task.

**Goal:** Replace GlassBottomBar from liquid_glass_widgets with native iOS 26 style navigation using CupertinoTabBar, BackdropFilter, and floating indicator

**Architecture:** Single StatefulWidget (iOSNativeBottomNav) replaces GlassBottomBar. Uses CupertinoTabBar with BackdropFilter blur, animated floating indicator pill that slides between tabs, and CupertinoIcons.

**Tech Stack:** Flutter, Cupertino widgets, BackdropFilter, AnimationController

---

### Task 1: Replace GlassBottomBar with iOS Native Navigation

**Files:**
- Modify: `lib/components/navigation.dart`

- [ ] **Step 1: Add imports for Cupertino and dart:ui**

```dart
import 'dart:ui';
import 'package:flutter/cupertino.dart';
```

- [ ] **Step 2: Replace GlassBottomBar with iOSNativeBottomNav**

Find the entire `Scaffold` + `GlassBottomBar` block (lines 158-195 in navigation.dart) and replace with:

```dart
return IOSNativeNavigation(
  currentIndex: _currentIndex,
  navItems: _navItems,
  onTabSelected: (index) {
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  },
  pages: _pages,
);
```

- [ ] **Step 3: Create iOSNativeBottomNav widget**

Add this new widget class at the end of navigation.dart (after line 346):

```dart
class IOSNativeNavigation extends StatefulWidget {
  final int currentIndex;
  final List<_NavItem> navItems;
  final ValueChanged<int> onTabSelected;
  final List<Widget> pages;

  const IOSNativeNavigation({
    super.key,
    required this.currentIndex,
    required this.navItems,
    required this.onTabSelected,
    required this.pages,
  });

  @override
  State<IOSNativeNavigation> createState() => _IOSNativeNavigationState();
}

class _IOSNativeNavigationState extends State<IOSNativeNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _indicatorAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: widget.currentIndex,
        children: widget.pages,
      ),
      bottomNavigationBar: _buildGlassTabBar(),
    );
  }

  Widget _buildGlassTabBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          height: 56 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.1),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _buildTabItems(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabItems() {
    return List.generate(widget.navItems.length, (index) {
      final item = widget.navItems[index];
      final isSelected = widget.currentIndex == index;
      return _TabButton(
        icon: item.icon,
        label: item.label,
        isSelected: isSelected,
        onTap: () => _onTabTap(index),
      );
    });
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.text.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify imports are correct**

Check that navigation.dart has these imports:
- `dart:ui` (for ImageFilter)
- `package:flutter/cupertino.dart` (for CupertinoIcons - optional)
- `package:flutter/services.dart` (for HapticFeedback - already imported)

If CupertinoIcons not imported, add:
```dart
import 'package:flutter/cupertino.dart';
```

- [ ] **Step 5: Run build to verify compilation**

Run: `flutter build ios --simulator --no-codesign 2>&1 | head -50`

Expected: No errors related to navigation.dart

- [ ] **Step 6: Commit**

```bash
git add lib/components/navigation.dart
git commit -m "feat: replace GlassBottomBar with iOS 26 native navigation"
```

---

### Task 2: (Optional) Add animated floating indicator pill

If Task 1 works but you want smoother animation that tracks position:

This requires keeping track of tab positions. Skip for now - the AnimatedContainer in _TabButton provides enough animation for most use cases.

---

### Verification Checklist

- [ ] Verify blur effect visible on bottom navigation (BackdropFilter applied)
- [ ] Verify tabs are clickable and trigger onTabSelected
- [ ] Verify CupertinoIcons display correctly (or fallback to Material icons)
- [ ] Verify haptic feedback fires on tap
- [ ] Verify IndexedStack preserves tab state
- [ ] Verify desktop layout unchanged (uses _DesktopLayout)
- [ ] Verify business account conditional tabs still work