import 'package:drift/drift.dart';
import '../database.dart';

part 'offline_auth.g.dart';

@DriftAccessor(tables: [OfflineUsers])
class OfflineAuthDao extends DatabaseAccessor<AppDatabase> with _$OfflineAuthDaoMixin {
  OfflineAuthDao(super.db);

  Future<OfflineUser?> getUserByEmail(String email) async {
    return (select(offlineUsers)..where((u) => u.email.equals(email))).getSingleOrNull();
  }

  Future<void> saveUser(OfflineUser user) async {
    await into(offlineUsers).insertOnConflictUpdate(user);
  }

  Future<List<OfflineUser>> getAllUsers() async {
    return await select(offlineUsers).get();
  }

  Future<void> setActiveUser(String email) async {
    await transaction(() async {
      await (update(offlineUsers)..where((u) => u.isActive.equals(1))).write(
        const OfflineUsersCompanion(isActive: Value(0)),
      );
      await (update(offlineUsers)..where((u) => u.email.equals(email))).write(
        const OfflineUsersCompanion(isActive: Value(1)),
      );
    });
  }

  Future<OfflineUser?> getActiveUser() async {
    return (select(offlineUsers)..where((u) => u.isActive.equals(1))).getSingleOrNull();
  }

  Future<int> deleteUser(String email) async {
    return await (delete(offlineUsers)..where((u) => u.email.equals(email))).go();
  }

  Future<bool> isUserLocal(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  Future<void> updatePasswordHash(String email, String hash) async {
    await (update(offlineUsers)..where((u) => u.email.equals(email))).write(
      OfflineUsersCompanion(passwordHash: Value(hash)),
    );
  }

  Future<void> markForSync(String email) async {
    await (update(offlineUsers)..where((u) => u.email.equals(email))).write(
      const OfflineUsersCompanion(needsSync: Value(1)),
    );
  }

  Future<void> clearSyncFlag(String email) async {
    await (update(offlineUsers)..where((u) => u.email.equals(email))).write(
      const OfflineUsersCompanion(needsSync: Value(0)),
    );
  }

  Future<List<OfflineUser>> getUsersNeedingSync() async {
    return (select(offlineUsers)..where((u) => u.needsSync.equals(1))).get();
  }

  Future<void> updateLastLogin(String email) async {
    await (update(offlineUsers)..where((u) => u.email.equals(email))).write(
      OfflineUsersCompanion(lastLogin: Value(DateTime.now().toIso8601String())),
    );
  }

  Future<void> updateUserData({
    required String email,
    String? fullName,
    String? country,
    String? accountType,
    String? hostingMode,
    String? avatarUrl,
    String? publicKey,
  }) async {
    await (update(offlineUsers)..where((u) => u.email.equals(email))).write(
      OfflineUsersCompanion(
        fullName: fullName != null ? Value(fullName) : const Value.absent(),
        country: country != null ? Value(country) : const Value.absent(),
        accountType: accountType != null ? Value(accountType) : const Value.absent(),
        hostingMode: hostingMode != null ? Value(hostingMode) : const Value.absent(),
        avatarUrl: avatarUrl != null ? Value(avatarUrl) : const Value.absent(),
        publicKey: publicKey != null ? Value(publicKey) : const Value.absent(),
      ),
    );
  }
}