// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passwords.dart';

// ignore_for_file: type=lint
mixin _$PasswordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PasswordsTable get passwords => attachedDatabase.passwords;
  PasswordsDaoManager get managers => PasswordsDaoManager(this);
}

class PasswordsDaoManager {
  final _$PasswordsDaoMixin _db;
  PasswordsDaoManager(this._db);
  $$PasswordsTableTableManager get passwords =>
      $$PasswordsTableTableManager(_db.attachedDatabase, _db.passwords);
}
