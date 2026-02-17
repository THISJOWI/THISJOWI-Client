import 'dart:ui';
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

      if (orgId == null) {
        if (mounted) {
          ErrorSnackBar.show(
              context, 'No Organization ID found in session'.i18n);
          setState(() => _isLoading = false);
        }
        return;
      }

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
        _organization = result['data'];
      } else {
        ErrorSnackBar.show(context, result['message']);
      }
      setState(() => _isSaving = false);
    }
  }

  Widget _buildGlassCard({required List<Widget> children, String? title}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isPassword = false,
    bool required = true,
    IconData? icon,
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
          prefixIcon: icon != null
              ? Icon(icon, color: AppColors.text.withOpacity(0.5), size: 20)
              : null,
          labelStyle: TextStyle(color: AppColors.text.withOpacity(0.5)),
          hintStyle: TextStyle(color: AppColors.text.withOpacity(0.2)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.2),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('LDAP Configuration'.i18n,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Ambient Background Gradients
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(color: Colors.transparent),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildGlassCard(
                      title: 'Connection Settings'.i18n,
                      children: [
                        _buildTextField(
                            controller: _ldapUrlController,
                            label: 'LDAP URL',
                            icon: Icons.link_rounded,
                            hint: 'ldap://example.com:389'),
                        _buildTextField(
                            controller: _ldapBaseDnController,
                            label: 'Base DN',
                            icon: Icons.account_tree_rounded,
                            hint: 'dc=example,dc=com'),
                        _buildTextField(
                            controller: _ldapBindDnController,
                            label: 'Bind DN (Optional)',
                            icon: Icons.person_pin_rounded,
                            hint: 'cn=admin,dc=example,dc=com',
                            required: false),
                        _buildTextField(
                            controller: _ldapBindPasswordController,
                            label: 'Bind Password (Optional)',
                            icon: Icons.vpn_key_rounded,
                            isPassword: true,
                            required: false),
                      ],
                    ),
                    _buildGlassCard(
                      title: 'User Search & Attributes'.i18n,
                      children: [
                        _buildTextField(
                            controller: _userSearchFilterController,
                            label: 'User Search Filter',
                            icon: Icons.search_rounded,
                            hint: '(&(objectClass=person)(uid={0}))'),
                        _buildTextField(
                            controller: _emailAttributeController,
                            label: 'Email Attribute',
                            icon: Icons.email_rounded,
                            hint: 'mail'),
                        _buildTextField(
                            controller: _fullNameAttributeController,
                            label: 'Full Name Attribute',
                            icon: Icons.badge_rounded,
                            hint: 'cn'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.05)),
                          ),
                          child: SwitchListTile(
                            title: Text('Enable LDAP Login'.i18n,
                                style: const TextStyle(
                                    color: AppColors.text, fontSize: 15)),
                            value: _ldapEnabled,
                            onChanged: (val) =>
                                setState(() => _ldapEnabled = val),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isTesting ? null : _testConnection,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.1)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: _isTesting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: AppColors.text))
                                : Text('Test Connection'.i18n,
                                    style: const TextStyle(
                                        color: AppColors.text,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveConfig,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text('Save Configuration'.i18n,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
