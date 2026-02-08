import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/data/models/user.dart';
import 'package:thisjowi/data/models/message.dart';
import 'package:thisjowi/screens/messages/ChatScreen.dart';
import 'package:thisjowi/services/messageService.dart';
// If needed for translations:
// import 'package:thisjowi/i18n/translations.dart';

class DialogUtils {
  static Future<void> showNewMessageDialog(BuildContext context,
      {VoidCallback? onSuccess}) async {
    final emailController = TextEditingController();
    final messageService = MessageService();
    
    // Get domain from SharedPreferences to fetch LDAP users
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final domain = email.contains('@') ? email.split('@').last : '';
    
    List<Map<String, dynamic>> ldapUsers = [];
    String? loadingError;

    // Fetch LDAP users
    if (domain.isNotEmpty) {
      final result = await messageService.getLdapUsers(domain);
      
      if (result['success'] == true && result['data'] is List) {
        ldapUsers = List<Map<String, dynamic>>.from(result['data']);
      } else {
        loadingError = result['message'] ?? 'Could not load LDAP users';
      }
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('New Message', style: TextStyle(color: AppColors.text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ldapUsers.isEmpty)
                Text('Enter email of the recipient',
                    style: TextStyle(
                        color: AppColors.text.withOpacity(0.7), fontSize: 13))
              else
                Text('Select a contact or enter an email',
                    style: TextStyle(
                        color: AppColors.text.withOpacity(0.7), fontSize: 13)),
              const SizedBox(height: 16),
              // LDAP Users List
              if (ldapUsers.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(minHeight: 100, maxHeight: 250),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.text.withOpacity(0.05),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: ldapUsers.length,
                    itemBuilder: (context, index) {
                      final user = ldapUsers[index];
                      final userEmail = user['email'] ?? '';
                      final fullName = user['fullName'] ?? user['ldapUsername'] ?? userEmail;
                      
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Text(
                          fullName,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          userEmail,
                          style: TextStyle(
                            color: AppColors.text.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          emailController.text = userEmail;
                        },
                        selected: emailController.text == userEmail,
                        selectedTileColor: AppColors.primary.withOpacity(0.2),
                      );
                    },
                  ),
                ),
              if (ldapUsers.isNotEmpty)
                const SizedBox(height: 16),
              // Email Input
              TextField(
                controller: emailController,
                autofocus: true,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'or type email',
                  labelStyle: TextStyle(color: AppColors.text.withOpacity(0.6)),
                  hintStyle: TextStyle(color: AppColors.text.withOpacity(0.4)),
                  filled: true,
                  fillColor: AppColors.text.withOpacity(0.05),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
              ),
              if (loadingError != null) ...[
                const SizedBox(height: 8),
                Text(
                  loadingError,
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
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
