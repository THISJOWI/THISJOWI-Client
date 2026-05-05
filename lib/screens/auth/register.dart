import 'package:flutter/material.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/auth/register_flow.dart';

import 'package:thisjowi/components/navigation.dart';
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

  @override
  Widget build(BuildContext context) {
    // Usar el nuevo flujo de registro interactivo
    return RegisterFlowScreen(
      isEmbedded: widget.isEmbedded,
      onSuccess: _handleSuccess,
    );
  }
}
