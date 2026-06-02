import 'package:flutter/material.dart';
import 'package:thisjowi/components/account_type_selector.dart';
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
  int _step = 0;
  String? _accountType;

  void _selectAccountType(String type) {
    setState(() {
      _accountType = type;
      _step = 1;
    });
  }

  void _goBack() {
    if (_step > 0) {
      setState(() {
        _step--;
        if (_step == 0) _accountType = null;
      });
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
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
        child: _step == 0
            ? AccountTypeSelector(
                onAccountTypeSelected: _selectAccountType,
              )
            : RegisterForm(
                accountType: _accountType ?? 'Community',
                onSuccess: _handleSuccess,
                onBack: _goBack,
              ),
      ),
    );
  }
}
