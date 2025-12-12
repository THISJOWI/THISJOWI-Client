import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dao/notes_dao.dart';
import 'dao/passwords_dao.dart';
import 'dao/otp_dao.dart';
import 'dao/auth_dao.dart';
import 'dao/sync_queue_dao.dart';

part 'app_database.g.dart';

/// Table definitions for drift
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get userEmail => text().named('user_email')();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get lastSyncedAt => text().nullable()();
  TextColumn get localId => text().unique().nullable()();
  IntColumn get serverId => integer().nullable()();
}

class Passwords extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get username => text()();
  TextColumn get password => text()();
  TextColumn get website => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get lastSyncedAt => text().nullable()();
  TextColumn get serverId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get action => text()();
  TextColumn get data => text().nullable()();
  TextColumn get createdAt => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}

class Users extends Table {
  TextColumn get email => text()();
  TextColumn get passwordHash => text().named('password_hash')();
  TextColumn get token => text().nullable()();
  TextColumn get lastLogin => text().nullable().named('last_login')();

  @override
  Set<Column> get primaryKey => {email};
}

class OtpEntries extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get issuer => text().nullable()();
  TextColumn get secret => text()();
  IntColumn get digits => integer().withDefault(const Constant(6))();
  IntColumn get period => integer().withDefault(const Constant(30))();
  TextColumn get algorithm => text().withDefault(const Constant('SHA1'))();
  TextColumn get type => text().withDefault(const Constant('totp'))();
  TextColumn get userId => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get lastSyncedAt => text().nullable()();
  TextColumn get serverId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database class using Drift - compatible with all platforms
@DriftDatabase(tables: [Notes, Passwords, SyncQueue, Users, OtpEntries], daos: [NotesDao, PasswordsDao, OtpDao, AuthDao, SyncQueueDao])
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase();
  factory AppDatabase.instance() => _instance;

  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(users);
        }
        if (from < 3) {
          await m.addColumn(notes, notes.userEmail);
          await customStatement(
            "UPDATE notes SET user_email = 'unknown@local' WHERE user_email IS NULL",
          );
        }
        if (from < 4) {
          await m.createTable(otpEntries);
        }
        if (from == 4) {
          await m.addColumn(otpEntries, otpEntries.type);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'thisjowi_encrypted',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
