import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/screens/otp/TOPT.dart';
import 'package:thisjowi/screens/home/HomeScreen.dart';
import 'package:thisjowi/screens/settings/SettingScreen.dart';
import 'package:thisjowi/screens/messages/MessagesScreen.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/services/autofillSaveHandler.dart';

// GlobalKey para acceder al estado de la navegación
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

  bool get isDesktop {
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

    // En desktop: usar sidebar lateral estilo Apple Music
    // En móvil: usar bottom navigation con Liquid Glass
    if (isDesktop) {
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

    // Layout móvil con Liquid Glass bottom bar
    return GlassBackdropScope(
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: GlassBottomBar(
          tabs: _navItems.map((item) => GlassBottomBarTab(
            icon: Icon(item.icon, size: 22),
            label: item.label,
          )).toList(),
          selectedIndex: _currentIndex,
          onTabSelected: (index) {
            HapticFeedback.lightImpact();
            setState(() => _currentIndex = index);
          },
          barHeight: 56,
          barBorderRadius: 28,
          horizontalPadding: 16,
          verticalPadding: 12,
          iconSize: 24,
          maskingQuality: MaskingQuality.high,
          selectedIconColor: AppColors.primary,
          unselectedIconColor: AppColors.text.withValues(alpha: 0.5),
          quality: GlassQuality.standard,
          showIndicator: true,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

/// Item de navegación para desktop
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

/// Layout para desktop con sidebar lateral estilo Apple Music
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
// Sidebar lateral izquierda estilo Apple Music
 Container(
 width: 220,
 color: AppColors.surface,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Logo/Header con imagen empresa.png
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
                // Items de navegación
                ...navItems.map((item) => _SidebarItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: currentIndex == item.index,
                  onTap: () => onItemSelected(item.index),
                )),
                const Spacer(),
                // Footer
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
          // Contenido principal
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

/// Item individual del sidebar
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
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
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
                  color: isSelected ? AppColors.primary : AppColors.text.withValues(alpha: 0.7),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.text.withValues(alpha: 0.9),
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
