import 'package:uuid/uuid.dart';
import '../models/password_entry.dart';
import '../local/app_database.dart';

/// Repository for managing passwords with offline-first approach
/// 
/// All operations go through local database first, then sync with backend
/// when connection is available
class PasswordsRepository {
  final AppDatabase _db = AppDatabase.instance();
  final Uuid _uuid = const Uuid();

  PasswordsRepository();

  /// Get all passwords from local database
  Future<Map<String, dynamic>> getAllPasswords() async {
    try {
      final localPasswords = await _db.passwordsDao.getAllPasswords();
      final passwords = localPasswords
          .map((data) => PasswordEntry.fromJson(data))
          .toList();

      return {
        'success': true,
        'data': passwords,
        'message': 'Passwords loaded from local storage'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load passwords: $e',
        'data': <PasswordEntry>[]
      };
    }
  }

  /// Create a new password (FAST - saved locally, synced in background)
  Future<Map<String, dynamic>> addPassword(
    Map<String, dynamic> passwordData,
  ) async {
    try {
      final localId = _uuid.v4();
      final now = DateTime.now();

      final dataToSave = {
        'id': localId,
        'title': passwordData['title'] ?? '',
        'username': passwordData['username'] ?? '',
        'password': passwordData['password'] ?? '',
        'website': passwordData['website'] ?? '',
        'notes': passwordData['notes'] ?? '',
        'userId': passwordData['userId'] ?? '',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'pending',
      };

      // Save to local database first (FAST)
      await _db.passwordsDao.insertPassword(dataToSave);

      // Sync disabled

      return {
        'success': true,
        'data': {'id': localId},
        'message': 'Password created successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create password: $e'
      };
    }
  }

  /// Update a password (FAST - saved locally, synced in background)
  Future<Map<String, dynamic>> updatePassword(
    String id,
    Map<String, dynamic> passwordData,
  ) async {
    try {
      final now = DateTime.now();

      final dataToUpdate = {
        'title': passwordData['title'],
        'username': passwordData['username'],
        'password': passwordData['password'],
        'website': passwordData['website'] ?? '',
        'notes': passwordData['notes'] ?? '',
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'pending',
      };

      // Update in local database first (FAST)
      await _db.passwordsDao.updatePassword(id, dataToUpdate);

      // Sync disabled

      return {
        'success': true,
        'message': 'Password updated successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update password: $e'
      };
    }
  }

  /// Delete a password (FAST - deleted locally, synced in background)
  Future<Map<String, dynamic>> deletePassword(String id, {String? serverId}) async {
    try {
      // Delete from local database first (FAST)
      await _db.passwordsDao.deletePassword(id);

      // Sync disabled

      return {
        'success': true,
        'message': 'Password deleted successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete password: $e'
      };
    }
  }

  /// Search passwords locally
  Future<Map<String, dynamic>> searchPasswords(String query) async {
    try {
      final localPasswords = await _db.passwordsDao.searchPasswords(query);
      final passwords = localPasswords
          .map((data) => PasswordEntry.fromJson(data))
          .toList();

      return {
        'success': true,
        'data': passwords,
        'message': 'Search results'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to search passwords: $e',
        'data': <PasswordEntry>[]
      };
    }
  }

  /// Force sync all pending changes
  Future<Map<String, dynamic>> syncAll() async {
    return {
      'success': true,
      'message': 'Sync is disabled'
    };
  }
}
