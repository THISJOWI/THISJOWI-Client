import '../models/otp_entry.dart' as model;
import '../service/otp_service.dart' as backend;

/// Repository para gestionar las entradas OTP con enfoque offline-first
/// 
/// All operations go through local database first, then sync with backend
/// when connection is available via SyncService
class OtpRepository {
  final backend.OtpService _otpService = backend.OtpService();

  OtpRepository();

  /// Obtener todas las entradas OTP
  Future<Map<String, dynamic>> getAllOtpEntries() async {
    return await _otpService.getAllOtpEntries();
  }

  /// Crear una nueva entrada OTP (FAST - saved locally, synced in background)
  Future<Map<String, dynamic>> addOtpEntry(Map<String, dynamic> entryData) async {
    return await _otpService.createOtpEntry(entryData);
  }

  /// Agregar OTP desde URI (otpauth://...) - FAST with background sync
  Future<Map<String, dynamic>> addOtpFromUri(String uri, String userId) async {
    return await _otpService.importFromUri(uri);
  }

  /// Actualizar una entrada OTP
  Future<Map<String, dynamic>> updateOtpEntry(
    String id,
    Map<String, dynamic> entryData,
  ) async {
    return await _otpService.updateOtpEntry(id, entryData);
  }

  /// Eliminar una entrada OTP (FAST - deleted locally, synced in background)
  Future<Map<String, dynamic>> deleteOtpEntry(String id, {String? serverId}) async {
    return await _otpService.deleteOtpEntry(id);
  }

  /// Buscar entradas OTP
  Future<Map<String, dynamic>> searchOtpEntries(String query) async {
    try {
      final result = await _otpService.getAllOtpEntries();
      if (!result['success']) {
        return result;
      }
      
      final entries = (result['data'] as List<model.OtpEntry>)
          .where((entry) =>
            entry.name.toLowerCase().contains(query.toLowerCase()) ||
            entry.issuer.toLowerCase().contains(query.toLowerCase())
          )
          .toList();

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
    return await _otpService.getOtpEntry(id);
  }

  /// Force a manual sync with the backend
  Future<Map<String, dynamic>> forceSync() async {
    return await _otpService.forceSync();
  }

  /// Get sync status for an OTP entry
  Future<String> getSyncStatus(String id) async {
    return await _otpService.getSyncStatus(id);
  }

  /// Get all pending sync entries count
  Future<int> getPendingSyncCount() async {
    return await _otpService.getPendingSyncCount();
  }

  /// Check if there are pending changes to sync
  Future<bool> hasPendingChanges() async {
    return await _otpService.hasPendingChanges();
  }

  /// Export OTP entry as URI
  String exportToUri(model.OtpEntry entry) {
    return _otpService.exportToUri(entry);
  }
}
