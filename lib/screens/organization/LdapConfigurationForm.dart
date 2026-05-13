import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/ldapAuthService.dart';

class LdapConfigurationForm extends StatefulWidget {
  const LdapConfigurationForm({super.key});

  @override
  State<LdapConfigurationForm> createState() => _LdapConfigurationFormState();
}

class _LdapConfigurationFormState extends State<LdapConfigurationForm> {
  final _formKey = GlobalKey<FormState>();
  final _ldapAuthService = LdapAuthService();

  // Form controllers
  late TextEditingController _ldapUrlController;
  late TextEditingController _ldapBaseDnController;
  late TextEditingController _ldapBindDnController;
  late TextEditingController _ldapBindPasswordController;
  late TextEditingController _userSearchFilterController;
  late TextEditingController _emailAttributeController;
  late TextEditingController _fullNameAttributeController;

  bool _isLoading = false;
  bool _testingConnection = false;
  String? _connectionStatus;
  bool _connectionValid = false;
  bool _showBindPassword = false;

  @override
  void initState() {
    super.initState();
    _ldapUrlController = TextEditingController();
    _ldapBaseDnController = TextEditingController();
    _ldapBindDnController = TextEditingController();
    _ldapBindPasswordController = TextEditingController();
    _userSearchFilterController = TextEditingController();
    _emailAttributeController = TextEditingController();
    _fullNameAttributeController = TextEditingController();

    _loadExistingConfiguration();
  }

  Future<void> _loadExistingConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');

    if (email != null) {
      final domain = email.split('@').last;
      final result = await _ldapAuthService.getOrganizationByDomain(domain);

      if (result['success'] == true && result['data'] != null) {
        final org = result['data'];
        setState(() {
          _ldapUrlController.text = org['ldapUrl'] ?? '';
          _ldapBaseDnController.text = org['ldapBaseDn'] ?? '';
          _ldapBindDnController.text = org['ldapBindDn'] ?? '';
          _userSearchFilterController.text = org['userSearchFilter'] ?? '(&(objectClass=person)(uid={0}))';
          _emailAttributeController.text = org['emailAttribute'] ?? 'mail';
          _fullNameAttributeController.text = org['fullNameAttribute'] ?? 'cn';
        });
      }
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _testingConnection = true);

    try {
      final request = {
        'ldapUrl': _ldapUrlController.text,
        'ldapBaseDn': _ldapBaseDnController.text,
        'ldapBindDn': _ldapBindDnController.text,
        'ldapBindPassword': _ldapBindPasswordController.text,
        'userSearchFilter': _userSearchFilterController.text,
      };

      // Call test connection endpoint
      final response = await _ldapAuthService.testLdapConnection(request);

      setState(() {
        _connectionValid = response['success'] == true;
        if (_connectionValid) {
          _connectionStatus = response['message'] ?? 'Conexión exitosa';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Conexión LDAP exitosa'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else {
          _connectionStatus = response['connectionError'] ?? response['credentialsError'] ?? 'Error de conexión';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $_connectionStatus'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _connectionValid = false;
        _connectionStatus = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al probar conexión: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _testingConnection = false);
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_connectionValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Debe probar la conexión LDAP antes de guardar'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final orgId = prefs.getString('orgId');

      if (orgId == null) {
        throw Exception('Organization ID not found');
      }

      final request = {
        'ldapUrl': _ldapUrlController.text,
        'ldapBaseDn': _ldapBaseDnController.text,
        'ldapBindDn': _ldapBindDnController.text,
        'ldapBindPassword': _ldapBindPasswordController.text,
        'userSearchFilter': _userSearchFilterController.text,
        'emailAttribute': _emailAttributeController.text,
        'fullNameAttribute': _fullNameAttributeController.text,
      };

      // Save configuration
      final response = await _ldapAuthService.updateOrganization(orgId, request);

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Configuración guardada exitosamente'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response['message']}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ldapUrlController.dispose();
    _ldapBaseDnController.dispose();
    _ldapBindDnController.dispose();
    _ldapBindPasswordController.dispose();
    _userSearchFilterController.dispose();
    _emailAttributeController.dispose();
    _fullNameAttributeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración LDAP'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📋 Configuración de Servidor LDAP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ingresa los detalles de tu servidor LDAP corporativo. '
                              'Haz clic en "Probar Conexión" para verificar que todos los '
                              'datos son correctos antes de guardar.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // LDAP URL
                    TextFormField(
                      controller: _ldapUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL del Servidor LDAP *',
                        hintText: 'ldap://ldap.example.com:389',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'URL del servidor es requerida';
                        }
                        if (!value!.startsWith('ldap://') && !value.startsWith('ldaps://')) {
                          return 'URL debe empezar con ldap:// o ldaps://';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Base DN
                    TextFormField(
                      controller: _ldapBaseDnController,
                      decoration: InputDecoration(
                        labelText: 'Base DN *',
                        hintText: 'dc=example,dc=com',
                        prefixIcon: const Icon(Icons.account_tree),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Base DN es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bind DN
                    TextFormField(
                      controller: _ldapBindDnController,
                      decoration: InputDecoration(
                        labelText: 'Bind DN (Opcional)',
                        hintText: 'cn=admin,dc=example,dc=com',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bind Password
                    TextFormField(
                      controller: _ldapBindPasswordController,
                      obscureText: !_showBindPassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña Bind (Opcional)',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showBindPassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => _showBindPassword = !_showBindPassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Search Filter
                    TextFormField(
                      controller: _userSearchFilterController,
                      decoration: InputDecoration(
                        labelText: 'Filtro de Búsqueda de Usuarios',
                        hintText: '(&(objectClass=person)(uid={0}))',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Attribute
                    TextFormField(
                      controller: _emailAttributeController,
                      decoration: InputDecoration(
                        labelText: 'Atributo de Email',
                        hintText: 'mail',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full Name Attribute
                    TextFormField(
                      controller: _fullNameAttributeController,
                      decoration: InputDecoration(
                        labelText: 'Atributo de Nombre Completo',
                        hintText: 'cn',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Connection Status
                    if (_connectionStatus != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _connectionValid ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.errorContainer,
                          border: Border.all(
                            color: _connectionValid ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _connectionValid ? Icons.check_circle : Icons.error,
                              color: _connectionValid ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _connectionStatus!,
                                style: TextStyle(
                                  color: _connectionValid ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testingConnection ? null : _testConnection,
                            icon: const Icon(Icons.bolt),
                            label: _testingConnection
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Probar Conexión'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.tertiary,
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _connectionValid ? _saveConfiguration : null,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
}
