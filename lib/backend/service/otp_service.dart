import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/otp_entry.dart' as model;
import 'database_service.dart';
import 'sync_service.dart';
import 'connectivity_service.dart';

/// Local-first OTP Service
/// 
/// This service implements a local-first architecture:
/// - All operations are performed locally first (instant response)
/// - Changes are synced to the backend in the background
/// - Works fully offline
/// - Automatic sync when connection is available
/// 
/// Contract:
/// - getAllOtpEntries() -> Future&lt;Map&gt; { success: bool, data?: List&lt;OtpEntry&gt;, message?: String }
/// - getOtpEntry(id) -> Future&lt;Map&gt; { success: bool, data?: OtpEntry, message?: String }
/// - createOtpEntry(entry) -> Future&lt;Map&gt; { success: bool, data?: OtpEntry, message?: String }
/// - updateOtpEntry(id, entry) -> Future&lt;Map&gt; { success: bool, data?: OtpEntry, message?: String }
/// - deleteOtpEntry(id) -> Future&lt;Map&gt; { success: bool, message?: String }
class OtpService {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final _uuid = const Uuid();

  OtpService();

  /// Get all OTP entries from local database
  /// Returns immediately from local storage
  Future<Map<String, dynamic>> getAllOtpEntries() async {
    try {
      final localEntries = await _dbService.getAllOtpEntries();
      
      // Filter out deleted entries
      final activeEntries = localEntries
          .where((e) => e['syncStatus'] != 'deleted')
          .toList();
      
      final entries = activeEntries.map((json) => model.OtpEntry.fromJson(json)).toList();
      
      // Trigger background sync if online
      _triggerBackgroundSync();
      
      return {'success': true, 'data': entries};
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch OTP entries: $e'};
    }
  }

  /// Get a single OTP entry by ID
  Future<Map<String, dynamic>> getOtpEntry(String id) async {
    try {
      final localEntry = await _dbService.getOtpEntryById(id);
      
      if (localEntry == null) {
        return {'success': false, 'message': 'OTP entry not found'};
      }
      
      if (localEntry['syncStatus'] == 'deleted') {
        return {'success': false, 'message': 'OTP entry not found'};
      }
      
      final entry = model.OtpEntry.fromJson(localEntry);
      return {'success': true, 'data': entry};
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch OTP entry: $e'};
    }
  }

  /// Create a new OTP entry locally and sync in background
  Future<Map<String, dynamic>> createOtpEntry(Map<String, dynamic> entryData) async {
    try {
      final now = DateTime.now().toIso8601String();
      final localId = _uuid.v4();
      
      final otpData = {
        'id': localId,
        'name': entryData['name'] ?? '',
        'issuer': entryData['issuer'] ?? '',
        'secret': entryData['secret'] ?? '',
        'digits': entryData['digits'] ?? 6,
        'period': entryData['period'] ?? 30,
        'algorithm': entryData['algorithm'] ?? 'SHA1',
        'createdAt': now,
        'updatedAt': now,
        'syncStatus': 'pending',
        'lastSyncedAt': null,
        'serverId': null,
      };
      
      await _dbService.insertOtpEntry(otpData);
      
      final entry = model.OtpEntry.fromJson(otpData);
      
      // Trigger background sync
      _triggerBackgroundSync();
      
      print('✅ OTP entry created locally: ${entry.name}');
      
      return {'success': true, 'data': entry};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create OTP entry: $e'};
    }
  }

  /// Update an OTP entry locally and sync in background
  Future<Map<String, dynamic>> updateOtpEntry(String id, Map<String, dynamic> entryData) async {
    try {
      // Check if entry exists
      final existingEntry = await _dbService.getOtpEntryById(id);
      if (existingEntry == null) {
        return {'success': false, 'message': 'OTP entry not found'};
      }
      
      if (existingEntry['syncStatus'] == 'deleted') {
        return {'success': false, 'message': 'OTP entry not found'};
      }
      
      final now = DateTime.now().toIso8601String();
      
      final updateData = {
        ...entryData,
        'updatedAt': now,
        'syncStatus': 'pending',
      };
      
      await _dbService.updateOtpEntry(id, updateData);
      
      // Get updated entry
      final updatedEntry = await _dbService.getOtpEntryById(id);
      if (updatedEntry == null) {
        return {'success': false, 'message': 'Failed to retrieve updated entry'};
      }
      
      final entry = model.OtpEntry.fromJson(updatedEntry);
      
      // Trigger background sync
      _triggerBackgroundSync();
      
      print('✅ OTP entry updated locally: ${entry.name}');
      
      return {'success': true, 'data': entry};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update OTP entry: $e'};
    }
  }

  /// Delete an OTP entry (soft delete locally, sync deletion in background)
  Future<Map<String, dynamic>> deleteOtpEntry(String id) async {
    try {
      // Check if entry exists
      final existingEntry = await _dbService.getOtpEntryById(id);
      if (existingEntry == null) {
        return {'success': false, 'message': 'OTP entry not found'};
      }
      
      final serverId = existingEntry['serverId'] as String?;
      
      if (serverId != null && serverId.isNotEmpty) {
        // Has been synced to server, mark as deleted for sync
        await _dbService.markOtpEntryAsDeleted(id);
        print('✅ OTP entry marked for deletion: $id');
      } else {
        // Never synced to server, delete directly
        await _dbService.deleteOtpEntry(id);
        print('✅ OTP entry deleted locally: $id');
      }
      
      // Trigger background sync
      _triggerBackgroundSync();
      
      return {'success': true, 'message': 'OTP entry deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete OTP entry: $e'};
    }
  }

  /// Force a manual sync with the backend
  Future<Map<String, dynamic>> forceSync() async {
    try {
      if (!_connectivityService.isOnline) {
        return {'success': false, 'message': 'No internet connection'};
      }
      
      final result = await _syncService.syncOtpEntries();
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Sync failed: $e'};
    }
  }

  /// Get sync status for an OTP entry
  Future<String> getSyncStatus(String id) async {
    try {
      final entry = await _dbService.getOtpEntryById(id);
      return entry?['syncStatus'] ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Get all pending sync entries count
  Future<int> getPendingSyncCount() async {
    try {
      final unsyncedEntries = await _dbService.getUnsyncedOtpEntries();
      final deletedEntries = await _dbService.getDeletedOtpEntries();
      return unsyncedEntries.length + deletedEntries.length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if there are pending changes to sync
  Future<bool> hasPendingChanges() async {
    return await getPendingSyncCount() > 0;
  }

  /// Trigger background sync (non-blocking)
  void _triggerBackgroundSync() {
    if (_connectivityService.isOnline) {
      // Use unawaited to not block the main operation
      Future.microtask(() async {
        try {
          await _syncService.syncOtpEntries();
        } catch (e) {
          print('Background OTP sync failed: $e');
        }
      });
    }
  }

  /// Import OTP entry from URI (otpauth://totp/...)
  Future<Map<String, dynamic>> importFromUri(String uri) async {
    try {
      final parsed = _parseOtpAuthUri(uri);
      if (parsed == null) {
        return {'success': false, 'message': 'Invalid OTP URI format'};
      }
      
      return await createOtpEntry(parsed);
    } catch (e) {
      return {'success': false, 'message': 'Failed to import OTP: $e'};
    }
  }

  /// Parse otpauth:// URI
  Map<String, dynamic>? _parseOtpAuthUri(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      
      if (uri.scheme != 'otpauth') return null;
      if (uri.host != 'totp' && uri.host != 'hotp') return null;
      
      // Get label (format: issuer:accountName or just accountName)
      final label = Uri.decodeComponent(uri.path.substring(1)); // Remove leading /
      String name;
      String issuer;
      
      if (label.contains(':')) {
        final parts = label.split(':');
        issuer = parts[0];
        name = parts.sublist(1).join(':');
      } else {
        name = label;
        issuer = uri.queryParameters['issuer'] ?? '';
      }
      
      // Get secret (required)
      final secret = uri.queryParameters['secret'];
      if (secret == null || secret.isEmpty) return null;
      
      // Get optional parameters
      final digits = int.tryParse(uri.queryParameters['digits'] ?? '6') ?? 6;
      final period = int.tryParse(uri.queryParameters['period'] ?? '30') ?? 30;
      final algorithm = (uri.queryParameters['algorithm'] ?? 'SHA1').toUpperCase();
      
      return {
        'name': name.trim(),
        'issuer': issuer.trim(),
        'secret': secret.toUpperCase(),
        'digits': digits,
        'period': period,
        'algorithm': algorithm,
      };
    } catch (e) {
      print('Failed to parse OTP URI: $e');
      return null;
    }
  }

  /// Export OTP entry as URI
  String exportToUri(model.OtpEntry entry) {
    final issuerEncoded = Uri.encodeComponent(entry.issuer);
    final nameEncoded = Uri.encodeComponent(entry.name);
    
    String label;
    if (entry.issuer.isNotEmpty) {
      label = '$issuerEncoded:$nameEncoded';
    } else {
      label = nameEncoded;
    }
    
    final params = <String, String>{
      'secret': entry.secret,
      'digits': entry.digits.toString(),
      'period': entry.period.toString(),
      'algorithm': entry.algorithm,
    };
    
    if (entry.issuer.isNotEmpty) {
      params['issuer'] = entry.issuer;
    }
    
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return 'otpauth://totp/$label?$queryString';
  }
}
