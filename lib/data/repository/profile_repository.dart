import 'package:thisjowi/data/local/database.dart';
import 'package:thisjowi/services/profile_service.dart';
import 'package:thisjowi/utils/app_logger.dart';

/// Repository for managing user profile with offline-first approach.
///
/// Profile data is cached locally so it survives offline and can react
/// to SSE sync events from sync-hub.
class ProfileRepository {
  final AppDatabase _db = AppDatabase.instance();
  final ProfileService _profileService = ProfileService();

  ProfileRepository();

  /// Get profile from local cache
  Future<Map<String, dynamic>?> getLocalProfile(String userId) async {
    return await _db.profileDao.getProfile(userId);
  }

  /// Fetch profile from server and cache locally
  Future<void> syncFromServer(String userId) async {
    try {
      final profile = await _profileService.getProfile(userId);
      await _db.profileDao.upsertProfile({
        'userId': profile.userId,
        'fullName': profile.fullName,
        'country': profile.country,
        'avatarUrl': profile.avatarUrl,
        'birthDate': profile.birthDate,
        'publicKey': profile.publicKey,
        'preferences': profile.preferences?.toString(),
        'accountType': profile.accountType,
        'hostingMode': profile.hostingMode,
        'updatedAt': profile.updatedAt?.toIso8601String(),
      });
    } catch (e) {
      appLog.e('ProfileRepository.syncFromServer failed', error: e);
    }
  }

  /// Update profile locally and sync to server
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final userId = data['userId']?.toString();
      if (userId == null || userId.isEmpty) return;

      await _db.profileDao.upsertProfile({
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await _profileService.updateProfileFields(
        fullName: data['fullName']?.toString(),
        country: data['country']?.toString(),
        birthDate: data['birthDate']?.toString(),
        accountType: data['accountType']?.toString(),
        hostingMode: data['hostingMode']?.toString(),
      );
    } catch (e) {
      appLog.e('ProfileRepository.updateProfile failed', error: e);
    }
  }

  /// Apply a remote change received via SSE
  Future<void> applyRemoteChange(Map<String, dynamic> payload) async {
    final userId = payload['userId']?.toString();
    if (userId == null || userId.isEmpty) return;

    try {
      final existing = await _db.profileDao.getProfile(userId);
      if (existing != null) {
        await _db.profileDao.upsertProfile({
          'userId': userId,
          'fullName': payload['fullName'] ?? existing['fullName'],
          'country': payload['country'] ?? existing['country'],
          'avatarUrl': payload['avatarUrl'] ?? existing['avatarUrl'],
          'birthDate': payload['birthDate'] ?? existing['birthDate'],
          'publicKey': payload['publicKey'] ?? existing['publicKey'],
          'preferences': payload['preferences']?.toString() ?? existing['preferences'],
          'accountType': payload['accountType'] ?? existing['accountType'],
          'hostingMode': payload['hostingMode'] ?? existing['hostingMode'],
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        await syncFromServer(userId);
      }
    } catch (e) {
      appLog.e('ProfileRepository.applyRemoteChange failed', error: e);
    }
  }

  /// Delete local profile (on logout or account deletion)
  Future<void> deleteLocalById(String userId) async {
    try {
      await _db.profileDao.deleteProfile(userId);
    } catch (e) {
      appLog.e('ProfileRepository.deleteLocalById failed', error: e);
    }
  }

  /// Clear all profiles (on logout)
  Future<void> clearAll() async {
    await _db.profileDao.deleteAll();
  }
}
