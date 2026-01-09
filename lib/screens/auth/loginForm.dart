import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/data/repository/auth_repository.dart';
import 'package:thisjowi/services/authService.dart';
import 'package:thisjowi/services/connectivityService.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/components/errorBar.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/components/Navigation.dart';
import 'package:thisjowi/screens/auth/forgotPassword.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback? onSuccess;

  const LoginForm({super.key, this.onSuccess});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  AuthRepository? _authRepository;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initAuthRepository();
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

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ErrorSnackBar.show(context, 'Please complete email and password'.i18n);
      return;
    }

    if (_authRepository == null) {
      _initAuthRepository();
    }

    setState(() => _isLoading = true);
    final result = await _authRepository!.login(email, password);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (result['offline'] == true && mounted) {
        ErrorSnackBar.showSuccess(context, 'Logged in offline mode'.i18n);
      }
      
      if (!mounted) return;
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
        );
      }
    } else {
      ErrorSnackBar.show(context, result['message'] ?? 'Login failed'.i18n);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field
        TextField(
          controller: _emailController,
          style: const TextStyle(color: AppColors.text),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email'.i18n,
            labelStyle: TextStyle(color: AppColors.text.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
          ),
          onSubmitted: (_) => _passwordFocusNode.requestFocus(),
        ),
        const SizedBox(height: 16),
        
        // Password Field
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            labelText: 'Password'.i18n,
            labelStyle: TextStyle(color: AppColors.text.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.text.withOpacity(0.5),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onSubmitted: (_) => _handleLogin(),
        ),
        
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              );
            },
            child: Text(
              'Forgot Password?'.i18n,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Login Button
        SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Sign In'.i18n,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
