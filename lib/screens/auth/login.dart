import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/data/repository/auth_repository.dart';
import 'package:thisjowi/services/authService.dart';
import 'package:thisjowi/services/biometricService.dart';
import 'package:thisjowi/services/connectivityService.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/components/Navigation.dart';
import 'package:thisjowi/components/errorBar.dart';
import 'package:thisjowi/i18n/translationService.dart';
import 'package:thisjowi/screens/auth/forgotPassword.dart';
import 'package:thisjowi/services/ldapAuthService.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final BiometricService _biometricService = BiometricService();
  final LdapAuthService _ldapAuthService = LdapAuthService();
  AuthRepository? _authRepository;
  bool _isLoading = false;
  bool _hasSavedSession = false;
  bool _biometricAvailable = false;
  String _biometricType = 'Biometric';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initAuthRepository();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final authService = AuthService();
    final token = await authService.getToken();
    final canCheck = await _biometricService.canCheckBiometrics();
    final isEnabled = await _biometricService.isBiometricEnabled();
    final biometricType = await _biometricService.getBiometricTypeName();

    if (mounted) {
      setState(() {
        _hasSavedSession = token != null && token.isNotEmpty;
        _biometricAvailable = canCheck && isEnabled && _hasSavedSession;
        _biometricType = biometricType;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);

    final authenticated = await _biometricService.authenticate(
      localizedReason: 'Authenticate to access ThisJowi'.tr(context),
    );

    if (authenticated && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
        (route) => false,
      );
    } else if (mounted) {
      setState(() => _isLoading = false);
      ErrorSnackBar.show(context, 'Authentication failed'.tr(context));
    }
  }

  void _initAuthRepository() {
    _authRepository = AuthRepository(
      authService: AuthService(),
      connectivityService: ConnectivityService(),
      secureStorageService: SecureStorageService(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final authRepository = AuthRepository(
        authService: AuthService(),
        connectivityService: ConnectivityService(),
        secureStorageService: SecureStorageService(),
      );

      final result = await authRepository.loginWithGoogle();

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
            (route) => false,
          );
        } else {
          ErrorSnackBar.show(
              context, result['message'] ?? 'Google Sign In failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMsg = e.toString().replaceFirst('Exception: ', '');
        ErrorSnackBar.show(context, errorMsg);
      }
    }
  }

  Future<void> _handleGitHubLogin() async {
    setState(() => _isLoading = true);

    final authRepository = AuthRepository(
      authService: AuthService(),
      connectivityService: ConnectivityService(),
      secureStorageService: SecureStorageService(),
    );

    try {
      final result = await authRepository.loginWithGitHub();

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
            (route) => false,
          );
        } else {
          ErrorSnackBar.show(
              context, result['message'] ?? 'GitHub login failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMsg = e.toString().replaceFirst('Exception: ', '');
        ErrorSnackBar.show(context, errorMsg);
      }
    }
  }

  /// Login automático con LDAP cuando el dominio del email lo tiene habilitado
  Future<void> _handleLdapLogin(
      String email, String password, String domain) async {
    final username = email.split('@')[0];

    setState(() => _isLoading = true);

    try {
      final result = await _ldapAuthService.loginWithLdap(
        domain: domain,
        username: username,
        password: password,
      );

      if (result['success'] == true && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
          (route) => false,
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackBar.show(context,
            result['message'] ?? 'LDAP authentication failed'.tr(context));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMsg = e.toString().replaceFirst('Exception: ', '');
        ErrorSnackBar.show(context, errorMsg);
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ErrorSnackBar.show(
          context, 'Please complete email and password'.tr(context));
      return;
    }

    // Verificar si el email tiene un dominio con LDAP habilitado
    if (email.contains('@')) {
      final domain = email.split('@')[1];
      final isLdapEnabled =
          await _ldapAuthService.isLdapEnabledForDomain(domain);

      if (isLdapEnabled) {
        await _handleLdapLogin(email, password, domain);
        return;
      }
    }

    if (_authRepository == null) {
      _initAuthRepository();
    }

    setState(() => _isLoading = true);
    final result = await _authRepository!.login(email, password);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Show message if offline login
      if (result['offline'] == true && mounted) {
        ErrorSnackBar.showSuccess(
            context, 'Logged in offline mode'.tr(context));
      }

      // Navigate to main screen replacing the stack
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
        (route) => false,
      );
    } else {
      ErrorSnackBar.show(
          context, result['message'] ?? 'Login failed'.tr(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Darker background for better contrast
      body: Stack(
        children: [
          // Ambient Background Gradients
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Blur effect for the background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.transparent),
          ),

          Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Icon with Glow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lock_person_rounded,
                          size: 70,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Welcome Text
                      Text(
                        "Welcome Back".tr(context),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sign in to continue".tr(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.text.withOpacity(0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Glassmorphism Login Form
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(32.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.white),
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  onFieldSubmitted: (_) =>
                                      _passwordFocusNode.requestFocus(),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: AppColors.text.withOpacity(0.7),
                                        size: 20),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 20),
                                    labelText: "Email".tr(context),
                                    labelStyle: TextStyle(
                                        color: AppColors.text.withOpacity(0.5)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                          color: AppColors.primary
                                              .withOpacity(0.5)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.black.withOpacity(0.2),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: AppColors.text.withOpacity(0.7),
                                        size: 20),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppColors.text.withOpacity(0.5),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    labelText: "Password".tr(context),
                                    labelStyle: TextStyle(
                                        color: AppColors.text.withOpacity(0.5)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                          color: AppColors.primary
                                              .withOpacity(0.5)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.black.withOpacity(0.2),
                                  ),
                                ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot Password?'.tr(context),
                                      style: TextStyle(
                                        color: AppColors.text.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Login Button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accent
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "Sign In".tr(context),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Social Login Buttons
                      if (!_isLoading)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google
                            _buildSocialButton(
                              asset: 'assets/google_logo.png',
                              onTap: _handleGoogleLogin,
                            ),
                            const SizedBox(width: 20),
                            // GitHub
                            _buildSocialButton(
                              asset: 'assets/github_logo_black.png',
                              useWhiteLogoBackground: true,
                              onTap: _handleGitHubLogin,
                              isIcon: false,
                            ),

                            if (_biometricAvailable) ...[
                              const SizedBox(width: 20),
                              // Biometric
                              GestureDetector(
                                onTap: _handleBiometricLogin,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Icon(
                                    _biometricType == 'Face ID'
                                        ? Icons.face_rounded
                                        : Icons.fingerprint_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                      const SizedBox(height: 30),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ".tr(context),
                            style: TextStyle(
                                color: AppColors.text.withValues(alpha: 0.6),
                                fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                                context, '/register'),
                            child: Text(
                              "Sign Up".tr(context),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String asset,
    required VoidCallback onTap,
    Color? color,
    Color? backgroundColor,
    bool isIcon = false,
    bool useWhiteLogoBackground = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.all(15),
        child: useWhiteLogoBackground
            ? Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: asset.startsWith('http')
                    ? Image.network(
                        asset,
                        color: color,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.code, color: AppColors.text, size: 30),
                      )
                    : Image.asset(
                        asset,
                        color: color,
                      ),
              )
            : (asset.startsWith('http')
                ? Image.network(
                    asset,
                    color: color,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.code, color: AppColors.text, size: 30),
                  )
                : Image.asset(
                    asset,
                    color: color,
                  )),
      ),
    );
  }
}
