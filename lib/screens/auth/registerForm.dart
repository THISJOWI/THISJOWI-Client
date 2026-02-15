import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/data/repository/auth_repository.dart';
import 'package:thisjowi/services/authService.dart';
import 'package:thisjowi/services/connectivityService.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/components/errorBar.dart';
import 'package:thisjowi/i18n/translations.dart';

class RegisterForm extends StatefulWidget {
  final Function(Map<String, dynamic> result) onSuccess;
  final String? accountType;
  final String? hostingMode;
  final String? initialCountry;
  final Map<String, dynamic>? ldapConfig;

  const RegisterForm({
    super.key,
    required this.onSuccess,
    this.accountType,
    this.hostingMode,
    this.initialCountry,
    this.ldapConfig,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final TextEditingController _countryController;
  final TextEditingController _birthdateController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _countryFocusNode = FocusNode();
  AuthRepository? _authRepository;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

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
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _countryController.dispose();
    _birthdateController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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

  Future<void> _showTermsDialog() async {
    String termsContent = '';
    final String languageCode = Localizations.localeOf(context).languageCode;
    final String assetPath = languageCode == 'es'
        ? 'assets/terms_and_conditions_es.txt'
        : 'assets/terms_and_conditions.txt';

    try {
      termsContent = await DefaultAssetBundle.of(context).loadString(assetPath);
    } catch (e) {
      termsContent =
          'Error loading terms and conditions. Please try again.'.i18n;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: Row(
          children: [
            const Icon(Icons.description_outlined, color: AppColors.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Terms and Conditions".i18n,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: SelectableText(
              termsContent,
              style: TextStyle(
                color: AppColors.text.withOpacity(0.85),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close".i18n,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ErrorSnackBar.show(context, 'Please complete all fields'.i18n);
      return;
    }

    if (!_acceptedTerms) {
      ErrorSnackBar.show(
          context, 'You must accept the terms and conditions'.i18n);
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

    // Step 1: Initiate registration (Send OTP)
    final result = await _authRepository!.initiateRegister(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showOtpDialog();
    } else {
      ErrorSnackBar.show(context,
          result['message'] ?? 'Failed to send verification code'.i18n);
    }
  }

  void _showOtpDialog() {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E)
                .withOpacity(0.9), // More transparent/darker
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            title: Text("Verify Email".i18n,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                )),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "We sent a code to ${_emailController.text}".i18n,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold),
                    maxLength: 6,
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "******",
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.2),
                          letterSpacing: 8),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.all(20),
            actions: [
              TextButton(
                onPressed:
                    isVerifying ? null : () => Navigator.pop(dialogContext),
                child: Text("Cancel".i18n,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w600)),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.accent],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          if (otpController.text.length < 6) return;
                          setDialogState(() => isVerifying = true);
                          await _completeRegistration(
                              otpController.text, dialogContext);
                          if (mounted) {
                            setDialogState(() => isVerifying = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text("Verify".i18n,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeRegistration(
      String otp, BuildContext dialogContext) async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final birthdate = _birthdateController.text.trim();

    final result = await _authRepository!.register(
      email,
      password,
      fullName: fullName,
      birthdate: birthdate.isNotEmpty ? birthdate : null,
      accountType: widget.accountType,
      hostingMode: widget.hostingMode,
      otp: otp,
      ldapConfig: widget.ldapConfig,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(dialogContext); // Close dialog

      // Auto login after successful registration
      final loginResult = await _authRepository!.login(email, password);

      if (!mounted) return;

      if (loginResult['success'] == true) {
        widget.onSuccess(loginResult['data']);
      } else {
        // Fallback to register result if login fails
        widget.onSuccess(result);
      }
    } else {
      // Show error in snackbar (using main context)
      ErrorSnackBar.show(context, result['message'] ?? 'Register failed'.i18n);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Full Name Field
        TextFormField(
          controller: _fullNameController,
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.person_outline,
                color: AppColors.text.withOpacity(0.7), size: 20),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            labelText: "Full Name".i18n,
            labelStyle: TextStyle(color: AppColors.text.withOpacity(0.5)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide:
                  const BorderSide(color: AppColors.secondary, width: 1),
            ),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 20),

        // Email Field
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.email_outlined,
                color: AppColors.text.withOpacity(0.7), size: 20),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            labelText: "Email".i18n,
            labelStyle: TextStyle(color: AppColors.text.withOpacity(0.5)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide:
                  const BorderSide(color: AppColors.secondary, width: 1),
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
          onFieldSubmitted: (_) => _isLoading ? null : _handleRegister(),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline,
                color: AppColors.text.withOpacity(0.7), size: 20),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
            labelText: "Password".i18n,
            labelStyle: TextStyle(color: AppColors.text.withOpacity(0.5)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide:
                  const BorderSide(color: AppColors.secondary, width: 1),
            ),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 20),

        // Terms and Conditions Checkbox
        Row(
          children: [
            Checkbox(
              value: _acceptedTerms,
              activeColor: AppColors.secondary,
              checkColor: Colors.black,
              side: BorderSide(color: AppColors.text.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              onChanged: (value) {
                setState(() {
                  _acceptedTerms = value ?? false;
                });
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: _showTermsDialog,
                child: RichText(
                  text: TextSpan(
                    text: "I accept the ".i18n,
                    style: TextStyle(
                        color: AppColors.text.withOpacity(0.7), fontSize: 13),
                    children: [
                      TextSpan(
                        text: "Terms and Conditions".i18n,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Register Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
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
                    "Create Account".i18n,
                    style: const TextStyle(
                      fontSize: 16,
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
