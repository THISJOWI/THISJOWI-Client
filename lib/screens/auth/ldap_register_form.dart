import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/core/exceptions/auth_exceptions.dart';
import 'package:thisjowi/services/ldapAuthService.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/i18n/translations.dart';

class LdapRegisterForm extends StatefulWidget {
  final Function(Map<String, dynamic> result) onSuccess;
  final VoidCallback onBack;
  final String hostingMode;

  const LdapRegisterForm({
    super.key,
    required this.onSuccess,
    required this.onBack,
    required this.hostingMode,
  });

  @override
  State<LdapRegisterForm> createState() => _LdapRegisterFormState();
}

class _LdapRegisterFormState extends State<LdapRegisterForm>
    with TickerProviderStateMixin {
  final TextEditingController _orgNameController = TextEditingController();
  final TextEditingController _ldapUrlController = TextEditingController();
  final TextEditingController _adminCnController = TextEditingController();
  final TextEditingController _dcController = TextEditingController();
  final TextEditingController _adminPasswordController =
      TextEditingController();

  final FocusNode _orgNameFocusNode = FocusNode();
  final FocusNode _ldapUrlFocusNode = FocusNode();
  final FocusNode _adminCnFocusNode = FocusNode();
  final FocusNode _dcFocusNode = FocusNode();
  final FocusNode _adminPasswordFocusNode = FocusNode();

  final LdapAuthService _ldapAuthService = LdapAuthService();

  bool _isLoading = false;
  bool _isTestingConnection = false;
  bool _connectionTested = false;
  bool _connectionValid = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

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

    _orgNameFocusNode
        .addListener(() => _onFocusChange(0, _orgNameFocusNode.hasFocus));
    _ldapUrlFocusNode
        .addListener(() => _onFocusChange(1, _ldapUrlFocusNode.hasFocus));
    _adminCnFocusNode
        .addListener(() => _onFocusChange(2, _adminCnFocusNode.hasFocus));
    _dcFocusNode.addListener(() => _onFocusChange(3, _dcFocusNode.hasFocus));
    _adminPasswordFocusNode
        .addListener(() => _onFocusChange(4, _adminPasswordFocusNode.hasFocus));
  }

  void _onFocusChange(int index, bool hasFocus) {
    setState(() => _focusedField = hasFocus ? index : -1);
  }

  @override
  void dispose() {
    _controller.dispose();
    _orgNameController.dispose();
    _ldapUrlController.dispose();
    _adminCnController.dispose();
    _dcController.dispose();
    _adminPasswordController.dispose();
    _orgNameFocusNode.dispose();
    _ldapUrlFocusNode.dispose();
    _adminCnFocusNode.dispose();
    _dcFocusNode.dispose();
    _adminPasswordFocusNode.dispose();
    super.dispose();
  }

  String? _validateLdapUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL LDAP es requerida'.i18n;
    }
    if (!value.startsWith('ldap://') && !value.startsWith('ldaps://')) {
      return 'URL LDAP debe comenzar con ldap:// o ldaps://'.i18n;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority) {
      return 'URL LDAP inválida'.i18n;
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido'.i18n;
    }
    return null;
  }

  Future<void> _testLdapConnection() async {
    final ldapUrl = _ldapUrlController.text.trim();
    final adminCn = _adminCnController.text.trim();
    final adminPassword = _adminPasswordController.text;
    final dc = _dcController.text.trim();

    final urlError = _validateLdapUrl(ldapUrl);
    if (urlError != null) {
      ErrorSnackBar.show(context, urlError);
      return;
    }

    final cnError = _validateRequired(adminCn, 'CN del administrador');
    if (cnError != null) {
      ErrorSnackBar.show(context, cnError);
      return;
    }

    final dcError = _validateRequired(dc, 'DC');
    if (dcError != null) {
      ErrorSnackBar.show(context, dcError);
      return;
    }

    if (adminPassword.isEmpty) {
      ErrorSnackBar.show(
          context, 'Contraseña del administrador es requerida'.i18n);
      return;
    }

    setState(() => _isTestingConnection = true);

    try {
      final result = await _ldapAuthService.testLdapConnection({
        'ldapUrl': ldapUrl,
        'ldapBaseDn': dc,
        'ldapBindDn': adminCn,
        'ldapBindPassword': adminPassword,
      });

      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _connectionTested = true;
          _connectionValid = result['success'] == true;
        });

        if (result['success'] == true) {
          ErrorSnackBar.showSuccess(context, 'Conexión LDAP exitosa'.i18n);
        } else {
          ErrorSnackBar.show(
              context, result['message'] ?? 'Error de conexión LDAP'.i18n);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _connectionTested = true;
          _connectionValid = false;
        });
        ErrorSnackBar.show(context, 'Error al probar conexión: $e'.i18n);
      }
    }
  }

  Future<void> _handleRegister() async {
    final orgName = _orgNameController.text.trim();
    final ldapUrl = _ldapUrlController.text.trim();
    final adminCn = _adminCnController.text.trim();
    final dc = _dcController.text.trim();
    final adminPassword = _adminPasswordController.text;

    final ldapBaseDn = dc.trim();
    if (ldapBaseDn.isEmpty) {
      ErrorSnackBar.show(context, 'DC es requerido'.i18n);
      return;
    }

    final urlError = _validateLdapUrl(ldapUrl);
    if (urlError != null) {
      ErrorSnackBar.show(context, urlError);
      return;
    }

    final cnError = _validateRequired(adminCn, 'CN del administrador');
    if (cnError != null) {
      ErrorSnackBar.show(context, cnError);
      return;
    }

    if (adminPassword.isEmpty) {
      ErrorSnackBar.show(
          context, 'Contraseña del administrador es requerida'.i18n);
      return;
    }

    if (orgName.isEmpty) {
      ErrorSnackBar.show(
          context, 'Nombre de organización es requerido'.i18n);
      return;
    }

    if (!_acceptedTerms) {
      ErrorSnackBar.show(
          context, 'Debes aceptar los términos y condiciones'.i18n);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _ldapAuthService.registerSelfHosted(
        ldapUrl: ldapUrl,
        ldapBaseDn: ldapBaseDn,
        ldapBindDn: adminCn,
        ldapBindPassword: adminPassword,
        orgName: orgName,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        widget.onSuccess({
          'orgId': data?['orgId'],
          'userId': data?['userId'],
          'email': data?['email'],
          'message': result['message'],
        });
      } else {
        ErrorSnackBar.show(context,
            result['message'] ?? 'Error al registrar organización'.i18n);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorSnackBar.show(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorSnackBar.show(context, 'Error al registrar: $e'.i18n);
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.description_outlined,
                  color: Theme.of(context).colorScheme.secondary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Terms and Conditions".i18n,
                style: TextStyle(
                  color: textColor,
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
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  termsContent,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.85),
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
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
        return SingleChildScrollView(
            child: Padding(
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
                      controller: _orgNameController,
                      focusNode: _orgNameFocusNode,
                      icon: Icons.business,
                      label: "Nombre de la organización".i18n,
                      hint: "Mi Empresa".i18n,
                      isFocused: _focusedField == 0,
                      textInputAction: TextInputAction.next,
                      onSubmitted: () => _ldapUrlFocusNode.requestFocus(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnimatedField(
                    index: 1,
                    child: _buildTextField(
                      controller: _ldapUrlController,
                      focusNode: _ldapUrlFocusNode,
                      icon: Icons.link,
                      label: "URL del servidor LDAP".i18n,
                      hint: "ldaps://ldap.empresa.com:636".i18n,
                      isFocused: _focusedField == 1,
                      textInputAction: TextInputAction.next,
                      onSubmitted: () => _adminCnFocusNode.requestFocus(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnimatedField(
                    index: 2,
                    child: _buildTextField(
                      controller: _adminCnController,
                      focusNode: _adminCnFocusNode,
                      icon: Icons.admin_panel_settings_outlined,
                      label: "CN del administrador".i18n,
                      hint: "cn=admin,dc=empresa,dc=com".i18n,
                      isFocused: _focusedField == 2,
                      textInputAction: TextInputAction.next,
                      onSubmitted: () => _dcFocusNode.requestFocus(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnimatedField(
                    index: 3,
                    child: _buildTextField(
                      controller: _dcController,
                      focusNode: _dcFocusNode,
                      icon: Icons.dns_outlined,
                      label: "DC (Domain Component)".i18n,
                      hint: "dc=empresa,dc=com".i18n,
                      isFocused: _focusedField == 3,
                      textInputAction: TextInputAction.next,
                      onSubmitted: () => _adminPasswordFocusNode.requestFocus(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnimatedField(
                    index: 4,
                    child: _buildPasswordField(),
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedField(
                    index: 6,
                    child: _buildTestConnectionButton(),
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedField(
                    index: 7,
                    child: _buildTermsCheckbox(),
                  ),
                  const SizedBox(height: 32),
                  _buildAnimatedField(
                    index: 8,
                    child: _buildCreateButton(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  Widget _buildLogo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4CAF50).withValues(alpha: 0.3),
              const Color(0xFF8BC34A).withValues(alpha: 0.2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          Icons.account_tree_outlined,
          size: 36,
          color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Text(
          'Configuración LDAP'.i18n,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configura tu servidor LDAP'.i18n,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: textColor.withValues(alpha: 0.5),
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
    TextInputAction? textInputAction,
    VoidCallback? onSubmitted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final baseAlpha = isDark ? Colors.white : Colors.black;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isFocused
                ? baseAlpha.withValues(alpha: isDark ? 0.1 : 0.08)
                : baseAlpha.withValues(alpha: isDark ? 0.05 : 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? baseAlpha.withValues(alpha: isDark ? 0.3 : 0.2)
                  : baseAlpha.withValues(alpha: isDark ? 0.1 : 0.08),
              width: isFocused ? 1.5 : 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(color: textColor, fontSize: 16),
            textInputAction: textInputAction,
            onFieldSubmitted: (_) => onSubmitted?.call(),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: isFocused
                    ? textColor.withValues(alpha: 0.8)
                    : textColor.withValues(alpha: 0.4),
                size: 20,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(
                color: isFocused
                    ? textColor.withValues(alpha: 0.8)
                    : textColor.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              hintStyle: TextStyle(
                color: textColor.withValues(alpha: 0.3),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final baseAlpha = isDark ? Colors.white : Colors.black;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _focusedField == 4
                ? baseAlpha.withValues(alpha: isDark ? 0.1 : 0.08)
                : baseAlpha.withValues(alpha: isDark ? 0.05 : 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focusedField == 4
                  ? baseAlpha.withValues(alpha: isDark ? 0.3 : 0.2)
                  : baseAlpha.withValues(alpha: isDark ? 0.1 : 0.08),
              width: _focusedField == 4 ? 1.5 : 1,
            ),
          ),
          child: TextFormField(
            controller: _adminPasswordController,
            focusNode: _adminPasswordFocusNode,
            obscureText: _obscurePassword,
            style: TextStyle(color: textColor, fontSize: 16),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.lock_outline,
                color: _focusedField == 4
                    ? textColor.withValues(alpha: 0.8)
                    : textColor.withValues(alpha: 0.4),
                size: 20,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _focusedField == 4
                      ? textColor.withValues(alpha: 0.8)
                      : textColor.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              labelText: "Contraseña del administrador LDAP".i18n,
              labelStyle: TextStyle(
                color: _focusedField == 4
                    ? textColor.withValues(alpha: 0.8)
                    : textColor.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestConnectionButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    final defaultFg = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return ElevatedButton.icon(
      onPressed: _isTestingConnection ? null : _testLdapConnection,
      icon: _isTestingConnection
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: isDark ? Colors.white : Theme.of(context).colorScheme.primary),
            )
          : Icon(
              _connectionTested
                  ? (_connectionValid ? Icons.check_circle : Icons.error)
                  : Icons.wifi_tethering,
              color: _connectionTested
                  ? (_connectionValid ? Colors.green : Colors.red)
                  : defaultFg,
              size: 20,
            ),
      label: Text(
        _isTestingConnection
            ? "Probando...".i18n
            : (_connectionTested
                ? (_connectionValid
                    ? "Conexión exitosa".i18n
                    : "Conexión fallida".i18n)
                : "Probar conexión LDAP".i18n),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _connectionTested
              ? (_connectionValid ? Colors.green : Colors.red)
              : defaultFg,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _connectionTested
            ? (_connectionValid
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.red.withValues(alpha: 0.15))
            : baseColor.withValues(alpha: isDark ? 0.1 : 0.08),
        foregroundColor: _connectionTested
            ? (_connectionValid ? Colors.green : Colors.red)
            : defaultFg,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _connectionTested
                ? (_connectionValid
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.3))
                : baseColor.withValues(alpha: isDark ? 0.1 : 0.08),
          ),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
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
                  ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _acceptedTerms
                    ? Theme.of(context).colorScheme.secondary
                    : textColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: _acceptedTerms
                ? Icon(Icons.check, size: 16, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSecondary)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _showTermsDialog,
            child: RichText(
              text: TextSpan(
                text: "Acepto los ".i18n,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: "Términos y Condiciones".i18n,
                    style: TextStyle(
                      color: textColor,
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
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4),
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
                "Crear cuenta LDAP".i18n,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final baseAlpha = isDark ? Colors.white : Colors.black;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: baseAlpha.withValues(alpha: isDark ? 0.06 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: baseAlpha.withValues(alpha: isDark ? 0.1 : 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                  ),
                ),
                child: const Icon(
                  Icons.account_tree,
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
                      'Business + LDAP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
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
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.hostingMode == 'Cloud'
                              ? 'Cloud'
                              : 'Self-Hosted',
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withValues(alpha: 0.5),
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
