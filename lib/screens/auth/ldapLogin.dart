import 'package:flutter/material.dart';
import '../../services/ldapAuthService.dart';

class LdapLoginScreen extends StatefulWidget {
  const LdapLoginScreen({super.key});

  @override
  State<LdapLoginScreen> createState() => _LdapLoginScreenState();
}

class _LdapLoginScreenState extends State<LdapLoginScreen> {
  final LdapAuthService _ldapAuthService = LdapAuthService();
  final _domainController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _domainController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLdapLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validar que el dominio tiene LDAP habilitado
      final isLdapEnabled = await _ldapAuthService.isLdapEnabledForDomain(
        _domainController.text.trim(),
      );

      if (!isLdapEnabled) {
        setState(() {
          _errorMessage = 'El dominio no tiene LDAP habilitado o no existe';
          _isLoading = false;
        });
        return;
      }

      // Intentar login LDAP
      final result = await _ldapAuthService.loginWithLdap(
        domain: _domainController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success'] == true && mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autenticación LDAP exitosa'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar a home
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        setState(() {
          _errorMessage = result['message'] ?? 'Error en autenticación LDAP';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login LDAP'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Icono y título
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.business,
                        size: 40,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Autenticación Empresarial',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa con tu cuenta LDAP corporativa',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Formulario
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Campo Dominio
                    TextFormField(
                      controller: _domainController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Dominio (ej: empresa.com)',
                        hintText: 'ejemplo.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.domain),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El dominio es requerido';
                        }
                        if (!value.contains('.')) {
                          return 'Ingresa un dominio válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo Username
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Usuario LDAP',
                        hintText: 'tu_usuario',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El usuario es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLdapLogin(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: '••••••••',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La contraseña es requerida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Mensaje de error
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Botón Login
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLdapLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade400,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Ingresar con LDAP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(
                      child: Container(height: 1, color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'O',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(
                      child: Container(height: 1, color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 24),

              // Link a login regular
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: RichText(
                  text: TextSpan(
                    text: '¿No tienes cuenta LDAP? ',
                    style: TextStyle(color: Colors.grey.shade700),
                    children: [
                      TextSpan(
                        text: 'Inicia sesión aquí',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
