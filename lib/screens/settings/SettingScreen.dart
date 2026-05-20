import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:thisjowi/core/exceptions/account_exceptions.dart';
import 'package:thisjowi/core/exceptions/profile_exceptions.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/services/account_service.dart';
import 'package:thisjowi/services/profile_service.dart';
import 'package:thisjowi/services/biometricService.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/components/country_selector.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/organization/LdapConfigScreen.dart';
import 'package:thisjowi/data/models/auth_user.dart';
import 'package:thisjowi/data/models/profile_user.dart';
import 'package:image_picker/image_picker.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final AuthService _authService = AuthService();
  final AccountService _accountService = AccountService();
  final ProfileService _profileService = ProfileService();
  final BiometricService _biometricService = BiometricService();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String _biometricType = 'Biometric';
  AuthUser? _currentAuthUser;
  ProfileUser? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadBiometricStatus(),
      _loadCurrentUser(),
    ]);
  }

  Future<void> _loadCurrentUser() async {
    final authUser = await _authService.getCurrentAuthUser();
    final profile = await _profileService.getCurrentProfile();

    if (mounted) {
      setState(() {
        _currentAuthUser = authUser;
        _currentProfile = profile;
      });
    }
  }

  Future<void> _loadBiometricStatus() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    final isSupported = await _biometricService.isDeviceSupported();
    final isEnabled = await _biometricService.isBiometricEnabled();
    final biometricType = await _biometricService.getBiometricTypeName();

    if (mounted) {
      setState(() {
        _biometricAvailable = canCheck && isSupported;
        _biometricEnabled = isEnabled;
        _biometricType = biometricType;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Authenticate before enabling
      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Authenticate to enable biometric lock'.i18n,
      );

      if (authenticated) {
        await _biometricService.setBiometricEnabled(true);
        if (mounted) {
          setState(() => _biometricEnabled = true);
          ErrorSnackBar.showSuccess(context, 'Biometric enabled'.i18n);
        }
      } else {
        if (mounted) {
          ErrorSnackBar.show(context, 'Authentication failed'.i18n);
        }
      }
    } else {
      await _biometricService.setBiometricEnabled(false);
      if (mounted) {
        setState(() => _biometricEnabled = false);
        ErrorSnackBar.showSuccess(context, 'Biometric disabled'.i18n);
      }
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    VoidCallback? onTap,
    bool isWarning = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = (isDark ? const Color(0xFF2A2A2A) : Colors.white)
        .withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: glassColor,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ??
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isWarning
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null && onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    Color confirmColor = Colors.red,
  }) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: 400,
          child: Dialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel'.i18n,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onConfirm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: confirmColor,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  void _handleDeleteAccount() async {
    _showConfirmationDialog(
      title: 'Delete Account'.i18n,
      content:
          'Are you sure you want to delete your account? This action cannot be undone.'
              .i18n,
      onConfirm: () {
        _showDeleteAccountPasswordDialog();
      },
    );
  }

  void _showDeleteAccountPasswordDialog() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Center(
          child: SizedBox(
            width: 400,
            child: Dialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Confirm Deletion'.i18n,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter your password to confirm account deletion.'.i18n,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Password'.i18n,
                          labelStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            size: 20,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                                size: 24,
                              ),
                              onPressed: () => setState(
                                  () => obscurePassword = !obscurePassword),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              passwordController.clear();
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel'.i18n,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final password = passwordController.text;
                              if (password.isEmpty) {
                                ErrorSnackBar.show(
                                  context,
                                  'Please enter your password'.i18n,
                                );
                                return;
                              }
                              Navigator.pop(context);
                              await _performAccountDeletion(password);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Delete Account'.i18n,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
  }

  Future<void> _performAccountDeletion(String password) async {
    try {
      await _accountService.deleteAccount(password);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      ErrorSnackBar.showSuccess(context, 'Account deleted successfully'.i18n);
    } on AccountException catch (e) {
      if (!mounted) return;
      ErrorSnackBar.show(context, e.message);
    } catch (e) {
      if (!mounted) return;
      ErrorSnackBar.show(context, '${'Error deleting account'.i18n}: $e');
    }
  }

  void _handleLogout() {
    _showConfirmationDialog(
      title: 'Logout'.i18n,
      content: 'Are you sure you want to logout?'.i18n,
      onConfirm: () {
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Center(
          child: SizedBox(
            width: 400,
            child: Dialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Change Password'.i18n,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: 'New Password'.i18n,
                      obscure: _obscureNewPassword,
                      onVisibilityToggle: () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword),
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password'.i18n,
                      obscure: _obscureConfirmPassword,
                      onVisibilityToggle: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel'.i18n,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleChangePassword(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.onSurface,
                              foregroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Change'.i18n,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onVisibilityToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.lock,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            size: 20,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
                size: 24,
              ),
              onPressed: onVisibilityToggle,
              tooltip: obscure ? 'Show Password'.i18n : 'Hide Password'.i18n,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _handleChangePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // New password and confirmation are required
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ErrorSnackBar.show(context, 'Please complete the new password'.i18n);
      return;
    }

    if (newPassword != confirmPassword) {
      ErrorSnackBar.show(context, 'The new passwords do not match'.i18n);
      return;
    }

    if (newPassword.length < 6) {
      ErrorSnackBar.show(
          context, 'Password must be at least 6 characters'.i18n);
      return;
    }

    try {
      // Use AccountService for password change
      await _accountService.changePassword('', newPassword, confirmPassword);
      if (!mounted) return;

      // Clear the text fields and close the dialog
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      Navigator.pop(context);

      ErrorSnackBar.showSuccess(context, 'Password changed successfully'.i18n);
    } on AccountException catch (e) {
      if (!mounted) return;
      ErrorSnackBar.show(context, e.message);
    } catch (e) {
      if (!mounted) return;
      ErrorSnackBar.show(context, '${'Error changing password'.i18n}: $e');
    }
  }

  void _showEditCountryDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Country'.i18n,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              CountrySelector(
                initialValue: _currentProfile?.country,
                onCountrySelected: (country) async {
                  if (country == null) return;
                  try {
                    await _profileService.updateProfileFields(
                      country: country,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ErrorSnackBar.showSuccess(context, 'Country updated'.i18n);
                    await _loadCurrentUser();
                  } catch (e) {
                    if (!mounted) return;
                    ErrorSnackBar.show(context, 'Error: $e');
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'.i18n,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAccountTypeDialog() {
    String? accountType;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text('Account Type'.i18n,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Business', 'Community']
                .map((type) => RadioListTile<String>(
                      title: Text(type,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface)),
                      value: type,
                      groupValue: accountType,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) => setState(() => accountType = value),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.i18n,
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (accountType == null) return;
                try {
                  await _profileService.updateProfileFields(
                    accountType: accountType,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ErrorSnackBar.showSuccess(
                      context, 'Account Type updated'.i18n);
                  await _loadCurrentUser();
                } catch (e) {
                  if (!mounted) return;
                  ErrorSnackBar.show(context, 'Error: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary),
              child: Text('Save'.i18n),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHostingModeDialog() {
    String? hostingMode;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text('Hosting Mode'.i18n,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Cloud', 'Self-Hosted']
                .map((mode) => RadioListTile<String>(
                      title: Text(mode,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface)),
                      value: mode,
                      groupValue: hostingMode,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) => setState(() => hostingMode = value),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.i18n,
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (hostingMode == null) return;
                try {
                  await _profileService.updateProfileFields(
                    hostingMode: hostingMode,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ErrorSnackBar.showSuccess(
                      context, 'Hosting Mode updated'.i18n);
                  await _loadCurrentUser();
                } catch (e) {
                  if (!mounted) return;
                  ErrorSnackBar.show(context, 'Error: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary),
              child: Text('Save'.i18n),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFullNameDialog() {
    final fullNameController = TextEditingController(
      text: _currentProfile?.fullName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Full Name'.i18n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: fullNameController,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Full Name'.i18n,
                      labelStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel'.i18n,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final fullName = fullNameController.text.trim();
                        if (fullName.isEmpty) {
                          ErrorSnackBar.show(
                            context,
                            'Full name cannot be empty'.i18n,
                          );
                          return;
                        }
                        try {
                          await _profileService.updateProfileFields(
                            fullName: fullName,
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                          ErrorSnackBar.showSuccess(
                            context,
                            'Full name updated'.i18n,
                          );
                          await _loadCurrentUser();
                        } catch (e) {
                          if (!mounted) return;
                          ErrorSnackBar.show(context, 'Error: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: Text('Save'.i18n),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      final File imageFile = File(image.path);
      await _profileService.uploadAvatar(imageFile);

      if (!mounted) return;
      ErrorSnackBar.showSuccess(context, 'Avatar updated'.i18n);
      await _loadCurrentUser();
    } on InvalidAvatarException catch (e) {
      if (!mounted) return;
      ErrorSnackBar.show(context, e.message);
    } catch (e) {
      if (!mounted) return;
      ErrorSnackBar.show(context, 'Error uploading avatar: $e');
    }
  }

  Future<void> _deleteAvatar() async {
    _showConfirmationDialog(
      title: 'Delete Avatar'.i18n,
      content: 'Are you sure you want to remove your profile picture?'.i18n,
      confirmColor: Theme.of(context).colorScheme.error,
      onConfirm: () async {
        try {
          await _profileService.deleteAvatar();
          if (!mounted) return;
          ErrorSnackBar.showSuccess(context, 'Avatar removed'.i18n);
          await _loadCurrentUser();
        } catch (e) {
          if (!mounted) return;
          ErrorSnackBar.show(context, 'Error: $e');
        }
      },
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Profile Picture'.i18n,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
                title: Text(
                  'Choose from Gallery'.i18n,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar();
                },
              ),
              if (_currentProfile?.avatarUrl != null)
                ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Remove Photo'.i18n,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = (isDark ? const Color(0xFF2A2A2A) : Colors.white)
        .withValues(alpha: 0.85);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: glassColor,
            child: Column(
              children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 12),
                  child: Row(
                    children: [
                      Icon(Icons.settings,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Settings'.i18n,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: GestureDetector(
                    onTap: _showAvatarOptions,
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.1),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.2),
                              width: 2,
                            ),
                            image: _currentProfile?.avatarUrl != null &&
                                    _currentProfile!.avatarUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(
                                        _currentProfile!.avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _currentProfile?.avatarUrl == null
                              ? Center(
                                  child: Text(
                                    _currentProfile?.initials ?? 'U',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentProfile?.fullName ?? 'User'.i18n,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentAuthUser?.email ?? '',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),

                // Settings List
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 120,
                    ),
                    children: [
                      // Full Name
                      _buildSettingItem(
                        icon: Icons.person,
                        title: 'Full Name'.i18n,
                        subtitle: _currentProfile?.fullName ?? 'Not set'.i18n,
                        onTap: _showEditFullNameDialog,
                      ),

                      // Country
                      _buildSettingItem(
                        icon: Icons.location_on,
                        title: 'Country'.i18n,
                        subtitle: _currentProfile?.country ?? 'Not set'.i18n,
                        onTap: _showEditCountryDialog,
                      ),

                      // Account Type
                      _buildSettingItem(
                        icon: Icons.business,
                        title: 'Account Type'.i18n,
                        subtitle:
                            _currentProfile?.accountType ?? 'Not set'.i18n,
                        onTap: _showEditAccountTypeDialog,
                      ),

                      // Hosting Mode
                      _buildSettingItem(
                        icon: Icons.cloud_queue,
                        title: 'Hosting Mode'.i18n,
                        subtitle: _currentProfile?.hostingMode ?? 'Cloud'.i18n,
                        onTap: _showEditHostingModeDialog,
                      ),

                      if (_currentAuthUser != null &&
                          _currentAuthUser!.isBusinessAccount) ...[
                        // LDAP Configuration
                        _buildSettingItem(
                          icon: Icons.admin_panel_settings,
                          title: 'LDAP Configuration'.i18n,
                          subtitle: 'Manage LDAP settings'.i18n,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LdapConfigScreen()),
                            );
                          },
                        ),
                      ],

                      // Change Password
                      if (_currentAuthUser != null &&
                          !_currentAuthUser!.isLdapUser &&
                          _currentAuthUser!.ldapUsername == null)
                        _buildSettingItem(
                          icon: Icons.password,
                          title: 'Change Password'.i18n,
                          subtitle: 'Update your password'.i18n,
                          onTap: _showChangePasswordDialog,
                        ),

                      // Biometric
                      if (_biometricAvailable)
                        _buildSettingItem(
                          icon: _biometricType == 'Face ID'
                              ? Icons.face_rounded
                              : Icons.fingerprint_rounded,
                          title: 'Biometric Authentication'.i18n,
                          subtitle: 'Use %s to unlock app'
                              .i18n
                              .fill([_biometricType]),
                          trailing: Switch(
                            value: _biometricEnabled,
                            onChanged: _toggleBiometric,
                            activeThumbColor:
                                Theme.of(context).colorScheme.onSurface,
                            activeTrackColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                            inactiveThumbColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            inactiveTrackColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.1),
                          ),
                        ),

                      // Application Version
                      _buildSettingItem(
                        icon: Icons.info_outline,
                        title: 'Application Version'.i18n,
                        subtitle: 'Development Version',
                      ),

                      // Account & Privacy
                      _buildSettingItem(
                        icon: Icons.help_outline,
                        title: 'Account & Privacy'.i18n,
                        onTap: () {},
                      ),

                      // Logout
                      _buildSettingItem(
                        icon: Icons.logout,
                        title: 'Logout'.i18n,
                        iconColor: Theme.of(context).colorScheme.tertiary,
                        onTap: _handleLogout,
                      ),

                      // Delete Account
                      _buildSettingItem(
                        icon: Icons.delete_forever,
                        title: 'Delete Account'.i18n,
                        subtitle: 'This action cannot be undone'.i18n,
                        iconColor: Theme.of(context).colorScheme.error,
                        onTap: _handleDeleteAccount,
                        isWarning: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
