import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/core/providers/otp_provider.dart';
import 'package:thisjowi/core/service_locator.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/services/otpService.dart';
import 'package:thisjowi/screens/password/EditPasswordScreen.dart';
import 'package:thisjowi/screens/notes/EditNoteScreen.dart';
import 'package:thisjowi/utils/DialogUtils.dart';
// import 'package:thisjowi/i18n/translations.dart';
// Using a naive translation helper for now to avoid compilation errors if imports differ
// Logic matches what was in TOPT.dart and HomeScreen.dart

class GlobalActions {
  static Future<void> createPassword(BuildContext context,
      {VoidCallback? onSuccess}) async {
    final sl = ServiceLocator();
    final repository = sl.passwordsRepository;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPasswordScreen(
          passwordsRepository: repository,
        ),
      ),
    );
    if (created == true && onSuccess != null) {
      onSuccess();
    }
  }

  static Future<void> createNote(BuildContext context,
      {VoidCallback? onSuccess}) async {
    final sl = ServiceLocator();
    final repository = sl.notesRepository;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(
          notesRepository: repository,
        ),
      ),
    );
    if (created == true && onSuccess != null) {
      onSuccess();
    }
  }

  static Future<void> createMessage(BuildContext context,
      {VoidCallback? onSuccess}) {
    return DialogUtils.showNewMessageDialog(context, onSuccess: onSuccess);
  }

  static Future<void> createOtp(BuildContext context,
      {VoidCallback? onSuccess}) async {
    final otpService = OtpService();

    final nameController = TextEditingController();
    final issuerController = TextEditingController();
    final secretController = TextEditingController();

    Widget buildTextField({
      required TextEditingController controller,
      required String label,
      String? hint,
    }) {
      return TextField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
        ),
      );
    }

    // Show Dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: 400,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: LiquidGlass.wrap(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text('Add OTP',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildTextField(
                            controller: nameController,
                            label: 'Account name',
                            hint: 'user@example.com',
                          ),
                          const SizedBox(height: 16),
                          buildTextField(
                            controller: issuerController,
                            label: 'Issuer',
                            hint: 'Google, GitHub...',
                          ),
                          const SizedBox(height: 16),
                          buildTextField(
                            controller: secretController,
                            label: 'Secret key',
                            hint: 'JBSWY3DPEHPK3PXP',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              context,
              borderRadius: 16,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      final secret = secretController.text.trim().replaceAll(' ', '');

      if (name.isEmpty || secret.isEmpty) {
        if (context.mounted) {
          ErrorSnackBar.show(context, 'Name and secret are required');
        }
        return;
      }

      if (!otpService.isValidSecret(secret)) {
        if (context.mounted) ErrorSnackBar.show(context, 'Invalid secret key');
        return;
      }

      // Use Provider to add OTP - this will notify all listeners
      if (context.mounted) {
        final otpProvider = context.read<OtpProvider>();
        final success = await otpProvider.addOtpEntry({
          'name': name,
          'issuer': issuerController.text.trim(),
          'secret': secret,
        });

        if (success) {
          ErrorSnackBar.showSuccess(context, 'OTP added');
          if (onSuccess != null) onSuccess();
        } else {
          ErrorSnackBar.show(context, otpProvider.errorMessage);
        }
      }
    }
  }
}
