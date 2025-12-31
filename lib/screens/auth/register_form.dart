import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/data/repository/auth_repository.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/services/connectivity_service.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/components/error_snack_bar.dart';
import 'package:thisjowi/i18n/translations.dart';

class RegisterForm extends StatefulWidget {
  final Function(Map<String, dynamic> result) onSuccess;
  final String? accountType;
  final String? hostingMode;
  final String? initialCountry;

  const RegisterForm({
    super.key, 
    required this.onSuccess,
    this.accountType,
    this.hostingMode,
    this.initialCountry,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final TextEditingController _countryController;
  final TextEditingController _birthdateController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _countryFocusNode = FocusNode();
  AuthRepository? _authRepository;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _countryController = TextEditingController(text: widget.initialCountry);
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
    _countryController.dispose();
    _birthdateController.dispose();
    _passwordFocusNode.dispose();
    _countryFocusNode.dispose();
    super.dispose();
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long'.i18n;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter'.i18n;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number'.i18n;
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character'.i18n;
    }
    return null;
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final country = _countryController.text.trim();
    final birthdate = _birthdateController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ErrorSnackBar.show(context, 'Please complete all fields'.i18n);
      return;
    }

    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      ErrorSnackBar.show(context, passwordError);
      return;
    }

    if (_authRepository == null) {
      _initAuthRepository();
    }

    setState(() => _isLoading = true);
    
    // Registration is now instant (offline-first with background sync)
    final result = await _authRepository!.register(
      email, 
      password,
      country: country.isNotEmpty ? country : null,
      birthdate: birthdate.isNotEmpty ? birthdate : null,
      accountType: widget.accountType,
      hostingMode: widget.hostingMode,
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      widget.onSuccess(result);
    } else {
      ErrorSnackBar.show(context, result['message'] ?? 'Register failed'.i18n);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Email Field
        TextFormField(
          controller: _emailController,
          style: const TextStyle(color: AppColors.text),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.secondary),
            labelText: "Email".i18n,
            labelStyle: TextStyle(color: AppColors.text.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.text.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.background.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 20),

        // Password Field
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          style: const TextStyle(color: AppColors.text),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _isLoading ? null : _handleRegister(),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: AppColors.secondary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.text.withOpacity(0.6),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            labelText: "Password".i18n,
            labelStyle: TextStyle(color: AppColors.text.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.text.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.background.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 20),

        // Country Field (Optional)
        TextFormField(
          controller: _countryController,
          focusNode: _countryFocusNode,
          style: const TextStyle(color: AppColors.text),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.public, color: AppColors.secondary),
            labelText: "Country (Optional)".i18n,
            labelStyle: TextStyle(color: AppColors.text.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.text.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.background.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 20),

        // Birthdate Field (Optional)
        TextFormField(
          controller: _birthdateController,
          style: const TextStyle(color: AppColors.text),
          readOnly: true,
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.secondary,
                      onPrimary: Colors.black,
                      surface: Color(0xFF202020),
                      onSurface: AppColors.text,
                    ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF202020)),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
              _birthdateController.text = formatted;
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.calendar_today, color: AppColors.secondary),
            labelText: "Birthdate (Optional)".i18n,
            labelStyle: TextStyle(color: AppColors.text.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.text.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.background.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 32),

        // Register Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.background,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Create Account".i18n,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
