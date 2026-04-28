// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_auth.dart';

// ignore_for_file: type=lint
mixin _$OfflineAuthDaoMixin on DatabaseAccessor<AppDatabase> {
  $OfflineUsersTable get offlineUsers => attachedDatabase.offlineUsers;
  OfflineAuthDaoManager get managers => OfflineAuthDaoManager(this);
}

class OfflineAuthDaoManager {
  final _$OfflineAuthDaoMixin _db;
  OfflineAuthDaoManager(this._db);
  $$OfflineUsersTableTableManager get offlineUsers =>
      $$OfflineUsersTableTableManager(_db.attachedDatabase, _db.offlineUsers);
}
