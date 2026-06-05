import 'package:flutter/material.dart';
import 'package:thisjowi/screens/auth/registerForm.dart';

class RegisterFlowScreen extends StatefulWidget {
  final bool isEmbedded;
  final Function(Map<String, dynamic>)? onSuccess;

  const RegisterFlowScreen({
    super.key,
    this.isEmbedded = false,
    this.onSuccess,
  });

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen> {
  final String _accountType = 'Community';

  void _goBack() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _handleSuccess(Map<String, dynamic> result) {
    if (widget.onSuccess != null) {
      widget.onSuccess!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RegisterForm(
          accountType: _accountType,
          onSuccess: _handleSuccess,
          onBack: _goBack,
        ),
      ),
    );
  }
}
