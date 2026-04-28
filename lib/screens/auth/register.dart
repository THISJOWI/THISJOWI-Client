import 'package:flutter/material.dart';
import 'package:thisjowi/core/exceptions/auth_exceptions.dart';
import 'package:thisjowi/components/errorBar.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/auth/register_flow.dart';

import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/components/Navigation.dart';
import 'package:thisjowi/screens/auth/emailVerification.dart';

class RegisterScreen extends StatefulWidget {
  final bool isEmbedded;
  final Function(Map<String, dynamic>)? onSuccess;

  const RegisterScreen({
    super.key,
    this.isEmbedded = false,
    this.onSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();

  void _handleSuccess(Map<String, dynamic> result) {
    final email = result['email'] as String;
    final token = result['token'] as String?;

    if (widget.onSuccess != null) {
      widget.onSuccess!({'email': email, 'token': token});
      return;
    }

    // Show success and navigate immediately
    if (mounted) {
      ErrorSnackBar.showSuccess(context, 'Account created!'.i18n);

      // Check if we have a token (auto-login successful)
      if (token != null && token.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyBottomNavigation()),
        );
      } else {
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
    try {
      final authUser = await _authService.loginWithGoogle();

      if (mounted) {
        _handleSuccess({
          'email': authUser.email,
          'token': authUser.token,
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'Google Sign Up failed: $e');
      }
    }
  }

  Future<void> _handleGitHubRegister() async {
    try {
      final authUser = await _authService.loginWithGitHub();

      if (mounted) {
        _handleSuccess({
          'email': authUser.email,
          'token': authUser.token,
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'GitHub Sign Up failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar el nuevo flujo de registro interactivo
    return RegisterFlowScreen(
      isEmbedded: widget.isEmbedded,
      onSuccess: _handleSuccess,
    );
  }
}
