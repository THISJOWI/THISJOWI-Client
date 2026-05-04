# Full Liquid Glass Navigation Implementation Plan

> **For agentic workers:** Use subagent-driven-development or executing-plans to implement this plan.

**Goal:** Implement full Liquid Glass navigation with sliding indicator, press animations, and page transitions

**Architecture:** Replace IOSNativeBottomNav with LiquidGlassBottomNav featuring sliding pill indicator, animated icons, and smooth transitions

**Tech Stack:** Flutter (AnimationController, AnimatedBuilder, PageTransition)

---

### Task 1: Implement Full Liquid Glass Navigation

**Files:**
- Modify: `lib/components/navigation.dart`

- [ ] **Step 1: Replace IOSNativeBottomNav with LiquidGlassBottomNav**

Replace the current IOSNativeBottomNav class with:

```dart
class LiquidGlassBottomNav extends StatefulWidget {
  final int currentIndex;
  final List<_NavItem> navItems;
  final ValueChanged<int> onTabSelected;
  final List<Widget> pages;

  const LiquidGlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.navItems,
    required this.onTabSelected,
    required this.pages,
  });

  @override
  State<LiquidGlassBottomNav> createState() => _LiquidGlassBottomNavState();
}

class _LiquidGlassBottomNavState extends State<LiquidGlassBottomNav>
    with TickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
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

  @override
  void didUpdateWidget(covariant LiquidGlassBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _indicatorController.forward(from: 0);
    }
  }

  void _onTabTap(int index) {
    HapticFeedback.lightImpact();
    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: _AnimatedPageStack(
        currentIndex: widget.currentIndex,
        pages: widget.pages,
      ),
      bottomNavigationBar: _LiquidGlassTabBar(
        currentIndex: widget.currentIndex,
        previousIndex: _previousIndex,
        navItems: widget.navItems,
        indicatorAnimation: _indicatorAnimation,
        onTabTap: _onTabTap,
      ),
    );
  }
}

class _AnimatedPageStack extends StatelessWidget {
  final int currentIndex;
  final List<Widget> pages;

  const _AnimatedPageStack({
    required this.currentIndex,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: IndexedStack(
        key: ValueKey(currentIndex),
        index: currentIndex,
        children: pages,
      ),
    );
  }
}

class _LiquidGlassTabBar extends StatelessWidget {
  final int currentIndex;
  final int previousIndex;
  final List<_NavItem> navItems;
  final Animation<double> indicatorAnimation;
  final ValueChanged<int> onTabTap;

  const _LiquidGlassTabBar({
    required this.currentIndex,
    required this.previousIndex,
    required this.navItems,
    required this.indicatorAnimation,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    final tabWidth = MediaQuery.of(context).size.width / navItems.length;
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          height: 56 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withAlpha(30),
                Colors.white.withAlpha(15),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withAlpha(40),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Stack(
              children: [
                // Sliding indicator
                _SlidingIndicator(
                  currentIndex: currentIndex,
                  previousIndex: previousIndex,
                  tabWidth: tabWidth,
                  animation: indicatorAnimation,
                ),
                // Tab buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(navItems.length, (index) {
                    final item = navItems[index];
                    return _AnimatedTabButton(
                      icon: item.icon,
                      label: item.label,
                      isSelected: currentIndex == index,
                      onTap: () => onTabTap(index),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlidingIndicator extends StatelessWidget {
  final int currentIndex;
  final int previousIndex;
  final double tabWidth;
  final Animation<double> animation;

  const _SlidingIndicator({
    required this.currentIndex,
    required this.previousIndex,
    required this.tabWidth,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final startPosition = previousIndex * tabWidth;
        final endPosition = currentIndex * tabWidth;
        final position = lerpDouble(startPosition, endPosition, animation.value) ?? startPosition;
        
        return Positioned(
          left: position + (tabWidth - 48) / 2,
          top: 8,
          child: Container(
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(50),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedTabButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedTabButton> createState() => _AnimatedTabButtonState();
}

class _AnimatedTabButtonState extends State<_AnimatedTabButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _scaleController.forward();
      },
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _scaleController.reverse();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: widget.isSelected
                          ? AppColors.primary
                          : AppColors.text.withAlpha(128),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                color: widget.isSelected
                    ? AppColors.primary
                    : AppColors.text.withAlpha(128),
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}
```

Note: `lerpDouble` is from `dart:ui`. Ensure the import is present.

- [ ] **Step 2: Update the build method to use LiquidGlassBottomNav**

Change the return statement in the build method from `IOSNativeBottomNav` to:

```dart
return LiquidGlassBottomNav(
  currentIndex: _currentIndex,
  navItems: _navItems,
  onTabSelected: (index) {
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  },
  pages: _pages,
);
```

- [ ] **Step 3: Add lerpDouble function if needed**

The `lerpDouble` function uses dart:ui's lerpDouble. Add this helper if not available:

```dart
double lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}
```

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze lib/components/navigation.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/components/navigation.dart
git commit -m "feat: add full liquid glass navigation with sliding indicator and animations"
```

---

### Verification Checklist

- [ ] Glass effect with blur + tint gradient visible
- [ ] Sliding indicator moves smoothly between tabs
- [ ] Press animation (scale + opacity) works on icons
- [ ] Page transitions with fade animation
- [ ] Label visible below each icon
- [ ] Haptic feedback on tap
- [ ] Spring animation feel on indicator
- [ ] Looks and feels like native iOS app