import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/data/models/user.dart';
import 'package:thisjowi/data/models/message.dart';
import 'package:thisjowi/screens/messages/ChatScreen.dart';
// If needed for translations:
// import 'package:thisjowi/i18n/translations.dart';

class DialogUtils {
  static Future<void> showNewMessageDialog(BuildContext context,
      {VoidCallback? onSuccess}) async {
    final emailController = TextEditingController();

    // Simple translation helper if not globally available
    String tr(String text) {
      // You might want to use your actual translation logic here
      // For now, returning text or implementing basic lookups if needed.
      // If the project uses context.tr() or 'string'.tr(context), we can pass context.
      return text;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('New Message', style: TextStyle(color: AppColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter email of the recipient',
                style: TextStyle(
                    color: AppColors.text.withOpacity(0.7), fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              autofocus: true,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: AppColors.text.withOpacity(0.6)),
                filled: true,
                fillColor: AppColors.text.withOpacity(0.05),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.text.withOpacity(0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () =>
                Navigator.pop(context, emailController.text.trim()),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversation: Conversation(
              id: 'new', // Flag for new conversation
              participants: [
                User(id: 'recipient', email: result), // Placeholder
              ],
              updatedAt: DateTime.now(),
            ),
          ),
        ),
      ).then((_) {
        if (onSuccess != null) onSuccess();
      });
    }
  }
}
