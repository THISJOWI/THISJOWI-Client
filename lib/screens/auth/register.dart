import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/components/errorBar.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/auth/registerForm.dart';

import 'package:thisjowi/services/authService.dart';
import 'package:thisjowi/data/repository/auth_repository.dart';
import 'package:thisjowi/services/connectivityService.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/components/Navigation.dart';
import 'package:thisjowi/screens/auth/emailVerification.dart';

class RegisterScreen extends StatefulWidget {
  final String? accountType;
  final String? hostingMode;
  final bool isEmbedded;
  final String? initialCountry;
  final Function(Map<String, dynamic>)? onSuccess;

  const RegisterScreen({
    super.key,
    this.accountType,
    this.hostingMode,
    this.isEmbedded = false,
    this.initialCountry,
    this.onSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  

// ...

  void _handleSuccess(Map<String, dynamic> result) {
    if (widget.onSuccess != null) {
      widget.onSuccess!(result);
      return;
    }

    // Show success and navigate immediately
    // Background sync will happen automatically
    if (mounted) {
      ErrorSnackBar.showSuccess(
        context, 
        'Account created!'.i18n
      );
      
      // Check if we have a token (auto-login successful)
      if (result.containsKey('token')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyBottomNavigation()),
        );
      } else {
        final email = result['email'] as String? ?? '';

        // Navigate to email verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(email: email),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleRegister() async {
    final authRepository = AuthRepository(
      authService: AuthService(),
      connectivityService: ConnectivityService(),
      secureStorageService: SecureStorageService(),
    );
    final result = await authRepository.loginWithGoogle();
    
    if (mounted) {
      if (result['success'] == true) {
        _handleSuccess(result['data'] ?? {});
      } else {
        ErrorSnackBar.show(context, result['message'] ?? 'Google Sign Up failed');
      }
    }
  }

  Future<void> _handleGitHubRegister() async {
    final authRepository = AuthRepository(
      authService: AuthService(),
      connectivityService: ConnectivityService(),
      secureStorageService: SecureStorageService(),
    );
    final result = await authRepository.loginWithGitHub();
    
    if (mounted) {
      if (result['success'] == true) {
        _handleSuccess(result['data'] ?? {});
      } else {
        ErrorSnackBar.show(context, result['message'] ?? 'GitHub Sign Up failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the content widget that is shared
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        // Logo/Icon with Glow
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person_add_rounded,
                              size: 56, // Smaller icon
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        
                        // Welcome Text
                        Text(
                          "Create Account".i18n,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28, // Smaller text
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign up to get started".i18n,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14, // Smaller text
                            color: AppColors.text.withOpacity(0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 24), // Reduced spacing

                        // Glassmorphism Register Form
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(24),
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
                              child: RegisterForm(
                                accountType: widget.accountType,
                                hostingMode: widget.hostingMode,
                                initialCountry: widget.initialCountry,
                                onSuccess: _handleSuccess,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Social Login Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google
                            _buildSocialButton(
                              asset: 'assets/google_logo.png',
                              onTap: _handleGoogleRegister,
                            ),
                            const SizedBox(width: 20),
                            // GitHub
                            _buildSocialButton(
                              asset: 'assets/github_logo_black.png',
                              useWhiteLogoBackground: true,
                              onTap: _handleGitHubRegister,
                            ),
                          ],
                        ),

                        if (!widget.isEmbedded) ...[
                          const SizedBox(height: 32),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ".i18n,
                                style: TextStyle(color: AppColors.text.withOpacity(0.6), fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/login',
                                    (route) => false,
                                  );
                                },
                                child: Text(
                                  "Sign In".i18n,
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient Background Gradients
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
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
          
          // Blur effect
          BackdropFilter(
             filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
             child: Container(color: Colors.transparent),
          ),

          content,
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String asset,
    required VoidCallback onTap,
    Color? color,
    Color? backgroundColor,
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