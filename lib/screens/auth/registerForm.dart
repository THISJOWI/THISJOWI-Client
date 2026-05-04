import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:thisjowi/components/country_selector.dart';
import 'package:thisjowi/core/app_colors.dart';
import 'package:thisjowi/core/exceptions/auth_exceptions.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/services/profile_service.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/i18n/translations.dart';

class RegisterForm extends StatefulWidget {
  final Function(Map<String, dynamic> result) onSuccess;
  final VoidCallback onBack;
  final String accountType;
  final String hostingMode;

  const RegisterForm({
    super.key,
    required this.onSuccess,
    required this.onBack,
    required this.accountType,
    required this.hostingMode,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm>
    with TickerProviderStateMixin {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _ldapUrlController = TextEditingController();
  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _serverUrlFocusNode = FocusNode();
  final FocusNode _ldapUrlFocusNode = FocusNode();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isTestingConnection = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  String? _selectedCountry;
  bool _connectionTested = false;

  late AnimationController _controller;
  int _focusedField = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _controller.forward();

    _fullNameFocusNode
        .addListener(() => _onFocusChange(0, _fullNameFocusNode.hasFocus));
    _emailFocusNode
        .addListener(() => _onFocusChange(1, _emailFocusNode.hasFocus));
    _passwordFocusNode
        .addListener(() => _onFocusChange(2, _passwordFocusNode.hasFocus));
    _serverUrlFocusNode
        .addListener(() => _onFocusChange(3, _serverUrlFocusNode.hasFocus));
    _ldapUrlFocusNode
        .addListener(() => _onFocusChange(4, _ldapUrlFocusNode.hasFocus));
  }

  void _onFocusChange(int index, bool hasFocus) {
    setState(() => _focusedField = hasFocus ? index : -1);
  }

  @override
  void dispose() {
    _controller.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _serverUrlController.dispose();
    _ldapUrlController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _serverUrlFocusNode.dispose();
    _ldapUrlFocusNode.dispose();
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

  String? _validateServerUrl(String? value) {
    if (widget.hostingMode == 'SelfHosted') {
      if (value == null || value.isEmpty) {
        return 'URL del servidor es requerida'.i18n;
      }
      if (!value.startsWith('http://') && !value.startsWith('https://')) {
        return 'URL debe comenzar con http:// o https://'.i18n;
      }
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasAuthority) {
        return 'URL inválida'.i18n;
      }
    }
    return null;
  }

  String? _validateLdapUrl(String? value) {
    if (widget.accountType == 'Business') {
      if (value == null || value.isEmpty) {
        return 'URL LDAP es requerida para cuentas Business'.i18n;
      }
      if (!value.startsWith('ldap://') && !value.startsWith('ldaps://')) {
        return 'URL LDAP debe comenzar con ldap:// o ldaps://'.i18n;
      }
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasAuthority) {
        return 'URL LDAP inválida'.i18n;
      }
    }
    return null;
  }

  Future<void> _testServerConnection() async {
    final url = _serverUrlController.text.trim();
    final error = _validateServerUrl(url);
    if (error != null) {
      ErrorSnackBar.show(context, error);
      return;
    }

    setState(() => _isTestingConnection = true);

    try {
      final response = await http.get(
        Uri.parse('$url/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() => _isTestingConnection = false);
        if (response.statusCode == 200) {
          setState(() => _connectionTested = true);
          ErrorSnackBar.showSuccess(context, 'connection_success'.i18n);
        } else {
          ErrorSnackBar.show(context, 'connection_failed'.i18n);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTestingConnection = false);
        ErrorSnackBar.show(context, 'connection_failed'.i18n);
      }
    }
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_outlined,
                  color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Terms and Conditions".i18n,
                style: const TextStyle(
                  color: Colors.white,
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  termsContent,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Close".i18n,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
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
    final serverUrl = _serverUrlController.text.trim();
    final ldapUrl = _ldapUrlController.text.trim();

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

    if (widget.hostingMode == 'SelfHosted') {
      final serverUrlError = _validateServerUrl(serverUrl);
      if (serverUrlError != null) {
        ErrorSnackBar.show(context, serverUrlError);
        return;
      }
    }

    // LDAP validation for Business
    if (widget.accountType == 'Business') {
      final ldapUrlError = _validateLdapUrl(ldapUrl);
      if (ldapUrlError != null) {
        ErrorSnackBar.show(context, ldapUrlError);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await _authService.initiateRegister(email);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showOtpDialog();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorSnackBar.show(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorSnackBar.show(context, 'Failed to send verification code'.i18n);
    }
  }

  void _showOtpDialog() {
    final otpController = TextEditingController();
    bool isVerifying = false;

    // Auto-verify when 6 digits entered
    otpController.addListener(() {
      if (otpController.text.length == 6 && !isVerifying) {
        setState(() => isVerifying = true);
        _completeRegistration(otpController.text, context).then((_) {
          if (mounted) setState(() => isVerifying = false);
        }).catchError((_) {
          if (mounted) setState(() => isVerifying = false);
        });
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.secondary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Verify Email".i18n,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "We sent a code to".i18n,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _emailController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      letterSpacing: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLength: 6,
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "• • • • • •",
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        letterSpacing: 8,
                        fontSize: 24,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.all(24),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isVerifying
                          ? null
                          : () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Cancel".i18n,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.accent],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isVerifying
                            ? null
                            : () async {
                                if (otpController.text.length < 6) return;
                                setDialogState(() => isVerifying = true);
                                final success = await _completeRegistration(
                                    otpController.text, dialogContext);
                                if (mounted) {
                                  if (success) Navigator.pop(dialogContext);
                                  setDialogState(() => isVerifying = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "Verify".i18n,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _completeRegistration(
      String otp, [BuildContext? dialogContext]) async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final serverUrl = _serverUrlController.text.trim();
    final ldapUrl = _ldapUrlController.text.trim();
    final country = _selectedCountry;

    try {
      final authUser = await _authService.register(
        email: email,
        password: password,
        otp: otp,
        fullName: fullName,
        country: country,
        accountType: widget.accountType,
        hostingMode: widget.hostingMode,
        serverUrl: widget.hostingMode == 'SelfHosted' ? serverUrl : null,
        ldapUrl: widget.accountType == 'Business' ? ldapUrl : null,
      );

      if (!mounted) return false;

      final profileService = ProfileService();
      await profileService.updateProfileFields(
        fullName: fullName,
        country: country,
      );

      if (!mounted) return false;

      widget.onSuccess({
        'email': authUser.email,
        'token': authUser.token,
        'userId': authUser.id,
      });
      
      return true;
    } on AuthException catch (e) {
      if (!mounted) return false;
      ErrorSnackBar.show(context, e.message);
      return false;
    }
  }

  int _getTermsCheckboxIndex() {
    int index = 4;
    if (widget.accountType == 'Business') index++;
    if (widget.hostingMode == 'SelfHosted') index += 2;
    return index;
  }

  int _getCreateButtonIndex() {
    int index = 5;
    if (widget.accountType == 'Business') index++;
    if (widget.hostingMode == 'SelfHosted') index += 2;
    return index;
  }

  Widget _buildAnimatedField({required int index, required Widget child}) {
    final delay = index * 0.08;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
          ),
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 20),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, delay + 0.3, curve: Curves.easeOutCubic),
          ),
        );
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: 340,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildTitle(),
                  const SizedBox(height: 32),
                  _buildSelectionSummary(),
                  const SizedBox(height: 32),
                  _buildAnimatedField(
                    index: 0,
                    child: _buildTextField(
                      controller: _fullNameController,
                      focusNode: _fullNameFocusNode,
                      icon: Icons.person_outline,
                      label: "Full Name".i18n,
                      isFocused: _focusedField == 0,
                      textInputAction: TextInputAction.next,
                      onSubmitted: () => _emailFocusNode.requestFocus(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnimatedField(
                    index: 1,
                    child: _buildTextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      icon: Icons.email_outlined,
                      label: "Email".i18n,
                      isFocused: _focusedField == 1,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: () => _passwordFocusNode.requestFocus(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnimatedField(
                    index: 2,
                    child: _buildPasswordField(),
                  ),
                  const SizedBox(height: 16),
                  _buildAnimatedField(
                    index: 3,
                    child: CountrySelector(
                      initialValue: _selectedCountry,
                      onCountrySelected: (country) {
                        setState(() => _selectedCountry = country);
                      },
                    ),
                  ),
                  if (widget.accountType == 'Business') ...[
                    const SizedBox(height: 16),
                    _buildAnimatedField(
                      index: 4,
                      child: _buildTextField(
                        controller: _ldapUrlController,
                        focusNode: _ldapUrlFocusNode,
                        icon: Icons.account_tree_outlined,
                        label: "LDAP URL".i18n,
                        hint: "ldaps://ldap.company.com".i18n,
                        isFocused: _focusedField == 4,
                        textInputAction: TextInputAction.next,
                        onSubmitted: () {
                          if (widget.hostingMode == 'SelfHosted') {
                            _serverUrlFocusNode.requestFocus();
                          }
                        },
                      ),
                    ),
                  ],
                  if (widget.hostingMode == 'SelfHosted') ...[
                    const SizedBox(height: 16),
                    _buildAnimatedField(
                      index: widget.accountType == 'Business' ? 5 : 4,
                      child: _buildTextField(
                        controller: _serverUrlController,
                        focusNode: _serverUrlFocusNode,
                        icon: Icons.link,
                        label: "Server URL".i18n,
                        hint: "https://your-server.com".i18n,
                        isFocused: _focusedField == 3,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAnimatedField(
                      index: widget.accountType == 'Business' ? 6 : 5,
                      child: _buildConnectionButton(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildAnimatedField(
                    index: _getTermsCheckboxIndex(),
                    child: _buildTermsCheckbox(),
                  ),
                  const SizedBox(height: 32),
                  _buildAnimatedField(
                    index: _getCreateButtonIndex(),
                    child: _buildCreateButton(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.3),
              AppColors.secondary.withValues(alpha: 0.2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(
          Icons.edit_note_outlined,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Completa tu registro'.i18n,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa tus datos para continuar'.i18n,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String label,
    String? hint,
    required bool isFocused,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    VoidCallback? onSubmitted,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isFocused
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              width: isFocused ? 1.5 : 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            onFieldSubmitted: (_) => onSubmitted?.call(),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: isFocused
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(
                color: isFocused
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _focusedField == 2
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focusedField == 2
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              width: _focusedField == 2 ? 1.5 : 1,
            ),
          ),
          child: TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.lock_outline,
                color: _focusedField == 2
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _focusedField == 2
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              labelText: "Password".i18n,
              labelStyle: TextStyle(
                color: _focusedField == 2
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionButton() {
    return ElevatedButton.icon(
      onPressed: _isTestingConnection ? null : _testServerConnection,
      icon: _isTestingConnection
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Icon(
              _connectionTested ? Icons.check_circle : Icons.wifi_tethering,
              color: _connectionTested ? Colors.green : Colors.white,
              size: 20,
            ),
      label: Text(
        _isTestingConnection
            ? "Testing...".i18n
            : (_connectionTested ? "Connected".i18n : "Test Connection".i18n),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _connectionTested ? Colors.green : Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _connectionTested
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.1),
        foregroundColor: _connectionTested ? Colors.green : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _connectionTested
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _acceptedTerms
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _acceptedTerms
                    ? AppColors.secondary
                    : Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: _acceptedTerms
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _showTermsDialog,
            child: RichText(
              text: TextSpan(
                text: "I accept the ".i18n,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: "Terms and Conditions".i18n,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
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
    );
  }

  Widget _buildSelectionSummary() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: widget.accountType == 'Business'
                        ? [const Color(0xFFFFA726), const Color(0xFFFFB74D)]
                        : [const Color(0xFF5B8DEF), const Color(0xFF7B9FE8)],
                  ),
                ),
                child: Icon(
                  widget.accountType == 'Business'
                      ? Icons.business_center
                      : Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.accountType == 'Business'
                          ? 'Business'
                          : 'Personal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          widget.hostingMode == 'Cloud'
                              ? Icons.cloud
                              : Icons.computer,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.hostingMode == 'Cloud'
                              ? 'Cloud'
                              : 'Self-Hosted',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
