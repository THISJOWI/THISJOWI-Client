import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/screens/otp/TOPT.dart';
import 'package:thisjowi/screens/home/HomeScreen.dart';
import 'package:thisjowi/screens/settings/SettingScreen.dart';
import 'package:thisjowi/screens/messages/MessagesScreen.dart';
import 'package:thisjowi/services/authService.dart';

// GlobalKey para acceder al estado de la navegación
final GlobalKey<Navigation> bottomNavigationKey = GlobalKey<Navigation>();

class MyBottomNavigation extends StatefulWidget {
  const MyBottomNavigation({super.key});

  @override
  State<MyBottomNavigation> createState() => Navigation();
}

class Navigation extends State<MyBottomNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  bool _isBusinessAccount = false;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _initNavigation();
  }

  Future<void> _initNavigation() async {
    // Check cached account type first for speed
    final cachedType = await _authService.getCachedAccountType();

    // Also fetch fresh user data to ensure accuracy
    final user = await _authService.getCurrentUser();

    if (mounted) {
      setState(() {
        _isBusinessAccount = (user?.accountType?.toLowerCase() == 'business') ||
            (cachedType?.toLowerCase() == 'business');
        _buildPages();
      });
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

  /// Método público para cambiar de pestaña
  void navigateToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  /// Navegar a la pestaña de OTP
  /// Finds the index of OtpScreen dynamically
  void navigateToOtp() {
    final index = _pages.indexWhere((widget) => widget is OtpScreen);
    if (index != -1) {
      navigateToTab(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure pages are built
    if (_pages.isEmpty) _buildPages();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          // Use IndexedStack to preserve state
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Liquid Glass Indicator
                          AnimatedPositioned(
                            duration: const Duration(
                                milliseconds:
                                    600), // Slightly slower for "fluid" feel
                            curve: Curves
                                .fastLinearToSlowEaseIn, // Apple-style organic ease
                            left: _currentIndex * 70.0,
                            top: 5,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withOpacity(0.2), // Subtle tint
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white
                                      .withOpacity(0.2), // Frosted edge
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  // Inner glow simulation
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: -5,
                                  ),
                                  // Glass refraction shadow
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                  stops: const [0.0, 0.4, 1.0],
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 15,
                                      sigmaY: 15), // Higher internal blur
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Icons Row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNavItem(
                                  0, Icons.house_rounded, Icons.house_outlined),
                              if (_isBusinessAccount) ...[
                                const SizedBox(width: 10),
                                _buildNavItem(1, Icons.chat_bubble_rounded,
                                    Icons.chat_bubble_outline),
                              ],
                              const SizedBox(width: 10),
                              _buildNavItem(_isBusinessAccount ? 2 : 1,
                                  Icons.shield_rounded, Icons.shield_outlined),
                              const SizedBox(width: 10),
                              _buildNavItem(
                                  _isBusinessAccount ? 3 : 2,
                                  Icons.settings_rounded,
                                  Icons.settings_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? Colors.white : AppColors.text.withOpacity(0.5),
          size: 26,
        ),
      ),
    );
  }
}
