// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp.dart';

// ignore_for_file: type=lint
mixin _$OtpDaoMixin on DatabaseAccessor<AppDatabase> {
  $OtpEntriesTable get otpEntries => attachedDatabase.otpEntries;
  OtpDaoManager get managers => OtpDaoManager(this);
}

class OtpDaoManager {
  final _$OtpDaoMixin _db;
  OtpDaoManager(this._db);
  $$OtpEntriesTableTableManager get otpEntries =>
      $$OtpEntriesTableTableManager(_db.attachedDatabase, _db.otpEntries);
}
