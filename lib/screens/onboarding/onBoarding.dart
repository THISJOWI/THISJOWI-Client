import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/components/errorBar.dart';
import 'package:thisjowi/screens/onboarding/countryMap.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // User Choices
  String? _accountType; // 'business', 'community'
  String? _hostingMode; // 'cloud', 'self-hosted'
  String? _authChoice; // 'login', 'register'
  
  // Registration Data
  final TextEditingController _urlController = TextEditingController();
  
  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Reset and replay animations
    _fadeController.reset();
    _scaleController.reset();
    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<Widget> _buildPages(BuildContext context) {
    List<Widget> pages = [
      _buildIntroPage(OnboardingPage(
        title: 'Welcome to THISJOWI'.i18n,
        description: 'Your productivity secured manager'.i18n,
        icon: Icons.lock_person_rounded,
        color: AppColors.primary,
      )),
      _buildIntroPage(OnboardingPage(
        title: 'Secure Storage'.i18n,
        description: 'All your passwords encrypted and safe'.i18n,
        icon: Icons.security,
        color: AppColors.accent,
      )),
      _buildIntroPage(OnboardingPage(
        title: 'Offline Access'.i18n,
        description: 'Access your data anytime, anywhere'.i18n,
        icon: Icons.cloud_off,
        color: AppColors.secondary,
      )),
      _buildIntroPage(OnboardingPage(
        title: 'Synchronization'.i18n,
        description: 'Keep your data synced'.i18n,
        icon: Icons.cloud_sync,
        color: AppColors.primary,
      )),
      _buildIntroPage(OnboardingPage(
        title: 'Biometric Security'.i18n,
        description: 'Quick and secure access with your fingerprint'.i18n,
        icon: Icons.fingerprint_rounded,
        color: AppColors.accent,
      )),
    ];

    // 5. Auth Choice (First question after intro)
    pages.add(_buildAuthChoicePage());

    // Path A: Register
    if (_authChoice == 'register') {
      // 6. Account Type
      pages.add(_buildAccountTypePage());

      // 7. Hosting Mode (Only if account type selected)
      if (_accountType != null) {
        pages.add(_buildHostingModePage());
      }

      // 8+. Registration Steps (Only if hosting mode selected)
      if (_hostingMode != null) {
        // Server Config (Only if Self-Hosted)
        if (_hostingMode == 'self-hosted') {
          pages.add(_buildServerConfigPage());
        }
        
        // Map Prompt -> Register
        pages.add(_buildMapPromptPage());
      }
    }
    
    // Path B: Login
    if (_authChoice == 'login') {
      // 6. Hosting Mode (Need to know if self-hosted)
      pages.add(_buildHostingModePage());
      
      // 7. Server Config (If self-hosted)
      if (_hostingMode == 'self-hosted') {
        pages.add(_buildServerConfigPage());
      }
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages(context);
    
    // Safety check: Ensure controller is in sync with current page
    if (_currentPage >= 5 && _pageController.hasClients && _pageController.page != null) {
      final page = _pageController.page!.round();
      if (page < 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_currentPage);
          }
        });
      }
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (Only on intro slides)
            if (_currentPage < 5)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip'.i18n,
                      style: TextStyle(
                        color: AppColors.text.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 60), // Spacer for alignment

            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: pages,
              ),
            ),

            // Page indicators (Always show)
            _buildPageIndicators(pages.length),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_ios, color: AppColors.text),
                          const SizedBox(width: 4),
                          Text(
                            'Back'.i18n,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 80),

                  // Next button (Only for intro slides)
                  if (_currentPage < 5)
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Next'.i18n,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 80), // Placeholder to maintain height
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Page Builders ---

  Widget _buildIntroPage(OnboardingPage page) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: page.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: page.color.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  page.icon,
                  size: 80,
                  color: page.color,
                ),
              ),
            ),
            const SizedBox(height: 60),
            Text(
              page.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              page.description,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.text.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.manage_accounts_outlined, size: 60, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Choose Account Type".i18n,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 40),
            _buildSelectionCard(
              title: "Community".i18n,
              description: "For personal use. Free forever.".i18n,
              icon: Icons.person_outline,
              isSelected: _accountType == 'community',
              onTap: () {
                setState(() => _accountType = 'community');
                _nextPage();
              },
            ),
            const SizedBox(height: 20),
            _buildSelectionCard(
              title: "Business".i18n,
              description: "For teams and organizations.".i18n,
              icon: Icons.business,
              isSelected: _accountType == 'business',
              onTap: () {
                setState(() => _accountType = 'business');
                _nextPage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostingModePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.storage_rounded, size: 60, color: AppColors.secondary),
              ),
            ),
             const SizedBox(height: 30),
            Text(
              "Select Hosting Mode".i18n,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 40),
            _buildSelectionCard(
              title: "Cloud".i18n,
              description: "Hosted by ThisJowi. Secure and managed.".i18n,
              icon: Icons.cloud_queue,
              isSelected: _hostingMode == 'cloud',
              onTap: () {
                setState(() => _hostingMode = 'cloud');
                if (_authChoice == 'login') {
                  _completeOnboarding();
                } else {
                  _nextPage();
                }
              },
            ),
            const SizedBox(height: 20),
            _buildSelectionCard(
              title: "Self-Hosted".i18n,
              description: "Host on your own server. Full control.".i18n,
              icon: Icons.dns_outlined,
              isSelected: _hostingMode == 'self-hosted',
              onTap: () {
                setState(() => _hostingMode = 'self-hosted');
                _nextPage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthChoicePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.rocket_launch_rounded, size: 60, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Get Started".i18n,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 40),
            _buildSelectionCard(
              title: "Create Account".i18n,
              description: "New to ThisJowi? Sign up here.".i18n,
              icon: Icons.person_add_outlined,
              isSelected: _authChoice == 'register',
              onTap: () {
                setState(() => _authChoice = 'register');
                _nextPage();
              },
            ),
            const SizedBox(height: 20),
            _buildSelectionCard(
              title: "Log In".i18n,
              description: "Already have an account?".i18n,
              icon: Icons.login,
              isSelected: _authChoice == 'login',
              onTap: () {
                setState(() => _authChoice = 'login');
                _nextPage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerConfigPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.text.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.text.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.settings_ethernet, size: 60, color: AppColors.text),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Server Configuration".i18n,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Enter your self-hosted server URL".i18n,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.text.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                labelText: "Server URL (e.g. https://api.myserver.com)".i18n,
                labelStyle: TextStyle(color: AppColors.text.withOpacity(0.6)),
                prefixIcon: Icon(Icons.link, color: AppColors.secondary),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.secondary, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if (_urlController.text.trim().isEmpty) {
                  ErrorSnackBar.show(context, 'Please enter server URL'.i18n);
                  return;
                }
                if (_authChoice == 'login') {
                  // Save URL and go to login
                  ApiConfig.saveManualBaseUrl(_urlController.text.trim());
                  _completeOnboarding();
                } else {
                  _nextPage();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text("Continue".i18n, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPromptPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.public, size: 60, color: AppColors.secondary),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Select Your Region".i18n,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "We need to know your location to optimize your experience.".i18n,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.text.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CountryMapScreen(
                        accountType: _accountType,
                        hostingMode: _hostingMode,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text("Select Country".i18n, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1) 
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: isSelected 
              ? Border.all(color: AppColors.primary, width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.text,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.primary
                : AppColors.text.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
