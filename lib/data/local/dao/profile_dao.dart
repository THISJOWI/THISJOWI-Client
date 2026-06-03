import 'package:drift/drift.dart';
import '../database.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [Profiles])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final query = select(profiles)
      ..where((p) => p.userId.equals(userId))
      ..limit(1);

    final results = await query.get();
    if (results.isEmpty) return null;

    final p = results.first;
    return {
      'userId': p.userId,
      'fullName': p.fullName,
      'country': p.country,
      'avatarUrl': p.avatarUrl,
      'birthDate': p.birthDate,
      'publicKey': p.publicKey,
      'preferences': p.preferences,
      'accountType': p.accountType,
      'hostingMode': p.hostingMode,
      'updatedAt': p.updatedAt,
    };
  }

  Future<void> upsertProfile(Map<String, dynamic> data) async {
    await into(profiles).insert(
      ProfilesCompanion.insert(
        userId: data['userId'] ?? '',
        fullName: Value(data['fullName']),
        country: Value(data['country']),
        avatarUrl: Value(data['avatarUrl']),
        birthDate: Value(data['birthDate']),
        publicKey: Value(data['publicKey']),
        preferences: Value(data['preferences']?.toString()),
        accountType: Value(data['accountType']),
        hostingMode: Value(data['hostingMode']),
        updatedAt: Value(data['updatedAt']),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<int> deleteProfile(String userId) async {
    return await (delete(profiles)..where((p) => p.userId.equals(userId))).go();
  }

  Future<void> deleteAll() async {
    await delete(profiles).go();
  }
}
