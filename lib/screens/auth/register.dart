import 'package:flutter/material.dart';
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

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyBottomNavigation()),
      );
    } else {
      final password = result['password'] as String?;
      final fullName = result['fullName'] as String?;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: email,
            password: password ?? '',
            fullName: fullName,
            onBack: () => Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RegisterFlowScreen(
      isEmbedded: widget.isEmbedded,
      onSuccess: _handleSuccess,
    );
  }
}
