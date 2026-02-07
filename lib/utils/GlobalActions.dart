import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/components/errorBar.dart';
import 'package:thisjowi/data/repository/passwordsRepository.dart';
import 'package:thisjowi/data/repository/notes_repository.dart';
import 'package:thisjowi/data/repository/otp_repository.dart';
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
    final repository = PasswordsRepository();
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
    final repository = NotesRepository();
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
    final otpRepository = OtpRepository();
    final otpService = OtpService();

    final nameController = TextEditingController();
    final issuerController = TextEditingController();
    final secretController = TextEditingController();

    // Helper for simple translation/text
    // In real app, reuse the existing translation mechanism
    String tr(String text) => text;

    Widget buildTextField({
      required TextEditingController controller,
      required String label,
      String? hint,
    }) {
      return TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: AppColors.text.withOpacity(0.7)),
          hintStyle: TextStyle(color: AppColors.text.withOpacity(0.3)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.text.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: AppColors.text.withOpacity(0.05),
        ),
      );
    }

    // Capture context before async gap
    final navigator = Navigator.of(context);

    // Show Dialog
    // Note: We need to import dart:io or similar if we want platform checks for QR scanning icons
    // For simplicity, we'll keep the manual add dialog here which works everywhere.
    // If QR scan is needed, we'd need to extract that logic or pass a callback.
    // Assuming manual entry for global action for now.

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add OTP', style: TextStyle(color: AppColors.text)),
        content: SingleChildScrollView(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.text.withOpacity(0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
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

      final addResult = await otpRepository.addOtpEntry({
        'name': name,
        'issuer': issuerController.text.trim(),
        'secret': secret,
      });

      if (context.mounted) {
        if (addResult['success'] == true) {
          ErrorSnackBar.showSuccess(context, 'OTP added');
          if (onSuccess != null) onSuccess();
        } else {
          ErrorSnackBar.show(context, addResult['message'] ?? 'Error');
        }
      }
    }
  }
}
