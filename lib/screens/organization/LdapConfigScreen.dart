import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/services/organizationService.dart';
import 'package:thisjowi/data/models/organization.dart';
import 'package:thisjowi/components/errorBar.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LdapConfigScreen extends StatefulWidget {
  const LdapConfigScreen({super.key});

  @override
  State<LdapConfigScreen> createState() => _LdapConfigScreenState();
}

class _LdapConfigScreenState extends State<LdapConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _organizationService = OrganizationService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  Organization? _organization;

  final _ldapUrlController = TextEditingController();
  final _ldapBaseDnController = TextEditingController();
  final _ldapBindDnController = TextEditingController();
  final _ldapBindPasswordController = TextEditingController();
  final _userSearchFilterController = TextEditingController();
  final _emailAttributeController = TextEditingController();
  final _fullNameAttributeController = TextEditingController();
  bool _ldapEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadOrganization();
  }

  Future<void> _loadOrganization() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final orgId = prefs.getString('orgId');

      // For now we might not have orgId in prefs if login was not LDAP or if regular user.
      // But let's assume valid user with org.
      // Actually we need to fetch org by domain or ID.
      // Let's try to get current user details to get orgId if missing.

      // If we don't have orgId, we can't load config.
      if (orgId == null) {
        // Try to get from user service or just show error
        // For development, let's assume we can get it or fail.
        if (mounted) {
          ErrorSnackBar.show(
              context, 'No Organization ID found in session'.i18n);
          setState(() => _isLoading = false);
        }
        return;
      }

      // We need getOrganizationById in Service, but we only have getOrganizationByDomain.
      // Let's assume we can get it by domain if we have user domain...
      // Or just implement getOrganizationById in backend/frontend.
      // Backend has getOrganizationById?
      // AuthRestController has getOrganization(id).

      // I implemented updateOrganization(id, data) in service.
      // I should add getOrganizationById(id) to service.
      // BUT for now, let's assume I can use domain if I have it.
      // User email has domain.
      final email = prefs.getString('email');
      if (email != null) {
        final domain = email.split('@').last;
        final result =
            await _organizationService.getOrganizationByDomain(domain);

        if (result['success'] == true) {
          _organization = result['data'];
          _populateFields();
        } else {
          if (mounted) ErrorSnackBar.show(context, result['message']);
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'Error loading organization: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateFields() {
    if (_organization == null) return;
    _ldapUrlController.text = _organization!.ldapUrl;
    _ldapBaseDnController.text = _organization!.ldapBaseDn;
    // Bind DN and Password might be hidden or empty if not returned by API for security?
    // Usually password is not returned.
    _userSearchFilterController.text = _organization!.userSearchFilter;
    _emailAttributeController.text = _organization!.emailAttribute;
    _fullNameAttributeController.text = _organization!.fullNameAttribute;
    _ldapEnabled = _organization!.ldapEnabled;
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

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    final result = await _organizationService.testLdapConnection(
      ldapUrl: _ldapUrlController.text,
      ldapBaseDn: _ldapBaseDnController.text,
      ldapBindDn: _ldapBindDnController.text.isNotEmpty
          ? _ldapBindDnController.text
          : null,
      ldapBindPassword: _ldapBindPasswordController.text.isNotEmpty
          ? _ldapBindPasswordController.text
          : null,
    );

    if (mounted) {
      if (result['success'] == true) {
        ErrorSnackBar.showSuccess(context, result['message']);
      } else {
        ErrorSnackBar.show(context, result['message']);
      }
      setState(() => _isTesting = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    if (_organization == null) return;

    setState(() => _isSaving = true);

    final data = {
      'ldapUrl': _ldapUrlController.text,
      'ldapBaseDn': _ldapBaseDnController.text,
      'userSearchFilter': _userSearchFilterController.text,
      'emailAttribute': _emailAttributeController.text,
      'fullNameAttribute': _fullNameAttributeController.text,
      'ldapEnabled': _ldapEnabled,
    };

    if (_ldapBindDnController.text.isNotEmpty) {
      data['ldapBindDn'] = _ldapBindDnController.text;
    }
    if (_ldapBindPasswordController.text.isNotEmpty) {
      data['ldapBindPassword'] = _ldapBindPasswordController.text;
    }

    final result =
        await _organizationService.updateOrganization(_organization!.id, data);

    if (mounted) {
      if (result['success'] == true) {
        ErrorSnackBar.showSuccess(context, 'LDAP Configuration saved'.i18n);
        _organization = result['data']; // Update local model
      } else {
        ErrorSnackBar.show(context, result['message']);
      }
      setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isPassword = false,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: AppColors.text),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: AppColors.text.withOpacity(0.7)),
          hintStyle: TextStyle(color: AppColors.text.withOpacity(0.3)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.text.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: AppColors.text.withOpacity(0.05),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_organization == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title: const Text("LDAP Configuration"),
            backgroundColor: Colors.transparent),
        body: Center(
            child: Text("Organization not found",
                style: TextStyle(color: AppColors.text))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('LDAP Configuration'.i18n),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connection Settings'.i18n,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _ldapUrlController,
                  label: 'LDAP URL',
                  hint: 'ldap://example.com:389'),
              _buildTextField(
                  controller: _ldapBaseDnController,
                  label: 'Base DN',
                  hint: 'dc=example,dc=com'),
              _buildTextField(
                  controller: _ldapBindDnController,
                  label: 'Bind DN (Optional)',
                  hint: 'cn=admin,dc=example,dc=com',
                  required: false),
              _buildTextField(
                  controller: _ldapBindPasswordController,
                  label: 'Bind Password (Optional)',
                  isPassword: true,
                  required: false),
              const SizedBox(height: 24),
              Text(
                'User Search & Attributes'.i18n,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _userSearchFilterController,
                  label: 'User Search Filter',
                  hint: '(&(objectClass=person)(uid={0}))'),
              _buildTextField(
                  controller: _emailAttributeController,
                  label: 'Email Attribute',
                  hint: 'mail'),
              _buildTextField(
                  controller: _fullNameAttributeController,
                  label: 'Full Name Attribute',
                  hint: 'cn'),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('Enable LDAP Login'.i18n,
                    style: const TextStyle(color: AppColors.text)),
                value: _ldapEnabled,
                onChanged: (val) => setState(() => _ldapEnabled = val),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isTesting ? null : _testConnection,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side:
                            BorderSide(color: AppColors.text.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isTesting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Test Connection'.i18n,
                              style: const TextStyle(color: AppColors.text)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('Save Configuration'.i18n,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
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
