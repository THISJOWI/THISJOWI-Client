import 'package:uuid/uuid.dart';
import '../models/otp_entry.dart' as model;
import '../local/app_database.dart';

/// Repository para gestionar las entradas OTP con enfoque offline-first
/// 
/// All operations go through local database first
class OtpRepository {
  final AppDatabase _db = AppDatabase.instance();
  final Uuid _uuid = const Uuid();

  OtpRepository();

  /// Obtener todas las entradas OTP
  Future<Map<String, dynamic>> getAllOtpEntries() async {
    try {
      final localEntries = await _db.otpDao.getAllOtpEntries();
      final entries = localEntries.map((e) => model.OtpEntry.fromJson(e)).toList();
      return {
        'success': true,
        'data': entries,
        'message': 'OTP entries loaded'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load OTP entries: $e',
        'data': <model.OtpEntry>[]
      };
    }
  }

  /// Crear una nueva entrada OTP (FAST - saved locally)
  Future<Map<String, dynamic>> addOtpEntry(Map<String, dynamic> entryData) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      
      final entry = {
        ...entryData,
        'id': id,
        'createdAt': now,
        'updatedAt': now,
        'syncStatus': 'pending',
      };
      
      await _db.otpDao.insertOtpEntry(entry);
      
      return {
        'success': true,
        'data': model.OtpEntry.fromJson(entry),
        'message': 'OTP entry created'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create OTP entry: $e'
      };
    }
  }

  /// Agregar OTP desde URI (otpauth://...) - FAST
  Future<Map<String, dynamic>> addOtpFromUri(String uriString, String userId) async {
    try {
      final uri = Uri.parse(uriString);
      if (uri.scheme != 'otpauth') {
        return {'success': false, 'message': 'Invalid URI scheme'};
      }

      final type = uri.host; // totp or hotp
      final path = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      // path usually is "Issuer:Account" or just "Account"
      
      String issuer = '';
      String account = path;
      
      if (path.contains(':')) {
        final parts = path.split(':');
        issuer = parts[0];
        account = parts.sublist(1).join(':');
      }

      final queryParams = uri.queryParameters;
      final secret = queryParams['secret'];
      final issuerParam = queryParams['issuer'];
      if (issuerParam != null && issuerParam.isNotEmpty) {
        issuer = issuerParam;
      }
      
      final algorithm = queryParams['algorithm'] ?? 'SHA1';
      final digits = int.tryParse(queryParams['digits'] ?? '6') ?? 6;
      final period = int.tryParse(queryParams['period'] ?? '30') ?? 30;

      if (secret == null) {
        return {'success': false, 'message': 'Missing secret in URI'};
      }

      final entryData = {
        'name': account,
        'issuer': issuer,
        'secret': secret,
        'type': type,
        'algorithm': algorithm,
        'digits': digits,
        'period': period,
        'userId': userId,
      };

      return await addOtpEntry(entryData);
    } catch (e) {
      return {'success': false, 'message': 'Failed to import URI: $e'};
    }
  }

  /// Actualizar una entrada OTP
  Future<Map<String, dynamic>> updateOtpEntry(
    String id,
    Map<String, dynamic> entryData,
  ) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updateData = {
        ...entryData,
        'updatedAt': now,
        'syncStatus': 'pending',
      };
      
      await _db.otpDao.updateOtpEntry(id, updateData);
      
      // Fetch updated
      final updated = await _db.otpDao.getOtpEntryById(id);
      
      return {
        'success': true,
        'data': updated != null ? model.OtpEntry.fromJson(updated) : null,
        'message': 'OTP entry updated'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update OTP entry: $e'
      };
    }
  }

  /// Eliminar una entrada OTP (FAST - deleted locally)
  Future<Map<String, dynamic>> deleteOtpEntry(String id, {String? serverId}) async {
    try {
      await _db.otpDao.deleteOtpEntry(id);
      return {
        'success': true,
        'message': 'OTP entry deleted'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete OTP entry: $e'
      };
    }
  }

  /// Buscar entradas OTP
  Future<Map<String, dynamic>> searchOtpEntries(String query) async {
    try {
      final localEntries = await _db.otpDao.searchOtpEntries(query);
      final entries = localEntries.map((e) => model.OtpEntry.fromJson(e)).toList();

      return {
        'success': true,
        'data': entries,
        'message': 'Search completed'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Search failed: $e',
        'data': <model.OtpEntry>[]
      };
    }
  }

  /// Get a single OTP entry by ID
  Future<Map<String, dynamic>> getOtpEntry(String id) async {
    try {
      final entry = await _db.otpDao.getOtpEntryById(id);
      if (entry == null) {
        return {'success': false, 'message': 'Entry not found'};
      }
      return {
        'success': true,
        'data': model.OtpEntry.fromJson(entry)
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Force a manual sync with the backend
  Future<Map<String, dynamic>> forceSync() async {
    return {'success': true, 'message': 'Sync is disabled'};
  }

  /// Get sync status for an OTP entry
  Future<String> getSyncStatus(String id) async {
    final entry = await _db.otpDao.getOtpEntryById(id);
    return entry?['syncStatus'] ?? 'unknown';
  }

  /// Get all pending sync entries count
  Future<int> getPendingSyncCount() async {
    final unsynced = await _db.otpDao.getUnsyncedOtpEntries();
    final deleted = await _db.otpDao.getDeletedOtpEntries();
    return unsynced.length + deleted.length;
  }

  /// Check if there are pending changes to sync
  Future<bool> hasPendingChanges() async {
    return (await getPendingSyncCount()) > 0;
  }

  /// Export OTP entry as URI
  String exportToUri(model.OtpEntry entry) {
    final label = entry.issuer.isNotEmpty 
        ? '${Uri.encodeComponent(entry.issuer)}:${Uri.encodeComponent(entry.name)}'
        : Uri.encodeComponent(entry.name);
        
    var uri = 'otpauth://${entry.type}/$label?secret=${entry.secret}';
    
    if (entry.issuer.isNotEmpty) {
      uri += '&issuer=${Uri.encodeComponent(entry.issuer)}';
    }
    
    if (entry.algorithm != 'SHA1') {
      uri += '&algorithm=${entry.algorithm}';
    }
    
    if (entry.digits != 6) {
      uri += '&digits=${entry.digits}';
    }
    
    if (entry.period != 30) {
      uri += '&period=${entry.period}';
    }
    
    return uri;
  }
}
