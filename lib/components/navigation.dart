import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/core/app_colors.dart';
import 'package:thisjowi/screens/otp/TOPT.dart';
import 'package:thisjowi/screens/home/HomeScreen.dart';
import 'package:thisjowi/screens/settings/SettingScreen.dart';
import 'package:thisjowi/screens/messages/MessagesScreen.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/services/autofillSaveHandler.dart';

final GlobalKey<Navigation> bottomNavigationKey = GlobalKey<Navigation>();

class MyBottomNavigation extends StatefulWidget {
  const MyBottomNavigation({super.key});

  @override
  State<MyBottomNavigation> createState() => Navigation();
}

class Navigation extends State<MyBottomNavigation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final AutofillSaveHandler _autofillHandler = AutofillSaveHandler();
  bool _isBusinessAccount = false;
  List<Widget> _pages = [];
  List<_NavItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initNavigation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autofillHandler.stopMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _autofillHandler.checkNow(context);
    }
  }

  Future<void> _initNavigation() async {
    final cachedType = await _authService.getCachedAccountType();
    final user = await _authService.getCurrentUser();

    if (mounted) {
      setState(() {
        final aspect = user?.accountType ?? cachedType;
        _isBusinessAccount = aspect?.toLowerCase() == 'business';
        _buildPages();
        _buildNavItems();
      });
      _autofillHandler.startMonitoring(context);
    }
  }

  void _buildPages() {
    _pages = [
      const HomeScreen(),
      if (_isBusinessAccount) const MessagesScreen(),
      const OtpScreen(),
      const SettingScreen(),
    ];
  }

  void _buildNavItems() {
    _navItems = [
      _NavItem(
        icon: Icons.house_rounded,
        label: 'Home',
        index: 0,
      ),
      if (_isBusinessAccount)
        _NavItem(
          icon: Icons.chat_bubble_rounded,
          label: 'Messages',
          index: 1,
        ),
      _NavItem(
        icon: Icons.shield_rounded,
        label: 'OTP',
        index: _isBusinessAccount ? 2 : 1,
      ),
      _NavItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        index: _isBusinessAccount ? 3 : 2,
      ),
    ];
  }

  void navigateToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  void navigateToOtp() {
    final index = _pages.indexWhere((widget) => widget is OtpScreen);
    if (index != -1) {
      navigateToTab(index);
    }
  }

  bool get _isDesktopPlatform {
    try {
      return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) _buildPages();
    if (_navItems.isEmpty) _buildNavItems();

    return LayoutBuilder(
      builder: (context, _) {
        final useSidebar =
            MediaQuery.of(context).size.width >= 600 || _isDesktopPlatform;

        if (useSidebar) {
          return _DesktopLayout(
            currentIndex: _currentIndex,
            navItems: _navItems,
            pages: _pages,
            onItemSelected: (index) {
              HapticFeedback.lightImpact();
              setState(() => _currentIndex = index);
            },
          );
        }

        return LiquidGlassBottomNav(
          currentIndex: _currentIndex,
          navItems: _navItems,
          onTabSelected: (index) {
            HapticFeedback.lightImpact();
            setState(() => _currentIndex = index);
          },
          pages: _pages,
        );
      },
    );
  }
}

double lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

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
    final screenWidth = MediaQuery.of(context).size.width;
    final totalPadding = 16.0 * 2;
    final tabWidth = (screenWidth - totalPadding) / navItems.length;
    
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
            child: SizedBox(
              height: 56,
              child: Stack(
                children: [
                  _SlidingIndicator(
                    currentIndex: currentIndex,
                    previousIndex: previousIndex,
                    tabWidth: tabWidth,
                    animation: indicatorAnimation,
                  ),
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
        final position = lerpDouble(startPosition, endPosition, animation.value);
        
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
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
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

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class _DesktopLayout extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> navItems;
  final List<Widget> pages;
  final ValueChanged<int> onItemSelected;

  const _DesktopLayout({
    required this.currentIndex,
    required this.navItems,
    required this.pages,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: 220,
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/empresa.png',
                        height: 40,
                        width: 40,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'THISJOWI',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 16),
                ...navItems.map((item) => _SidebarItem(
                      icon: item.icon,
                      label: item.label,
                      isSelected: currentIndex == item.index,
                      onTap: () => onItemSelected(item.index),
                    )),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'v1.0.2',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: IndexedStack(
                index: currentIndex,
                children: pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color:
            isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.text.withValues(alpha: 0.7),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.text.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
