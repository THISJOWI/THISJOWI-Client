import 'package:uuid/uuid.dart';
import '../models/otp_entry.dart' as model;
import '../service/database_service.dart';

/// Repository para gestionar las entradas OTP con enfoque offline-first
class OtpRepository {
  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  /// Obtener todas las entradas OTP
  Future<Map<String, dynamic>> getAllOtpEntries() async {
    try {
      final localEntries = await _dbService.getAllOtpEntries();
        final entries = localEntries
          .map((data) => model.OtpEntry.fromJson(data))
          .toList();

      return {
        'success': true,
        'data': entries,
        'message': 'OTP entries loaded successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load OTP entries: $e',
        'data': <model.OtpEntry>[]
      };
    }
  }

  /// Crear una nueva entrada OTP
  Future<Map<String, dynamic>> addOtpEntry(Map<String, dynamic> entryData) async {
    try {
      final localId = _uuid.v4();
      final now = DateTime.now();

      final dataToSave = {
        'id': localId,
        'name': entryData['name'] ?? '',
        'issuer': entryData['issuer'] ?? '',
        'secret': entryData['secret'] ?? '',
        'digits': entryData['digits'] ?? 6,
        'period': entryData['period'] ?? 30,
        'algorithm': entryData['algorithm'] ?? 'SHA1',
        'userId': entryData['userId'] ?? '',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'pending',
      };

      await _dbService.insertOtpEntry(dataToSave);

      return {
        'success': true,
        'data': {'id': localId},
        'message': 'OTP entry created successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create OTP entry: $e'
      };
    }
  }

  /// Agregar OTP desde URI (otpauth://...)
  Future<Map<String, dynamic>> addOtpFromUri(String uri, String userId) async {
    try {
      final entry = model.OtpEntry.fromUri(uri, userId);
      final localId = _uuid.v4();
      
      final dataToSave = {
        ...entry.toJson(),
        'id': localId,
        'syncStatus': 'pending',
      };

      await _dbService.insertOtpEntry(dataToSave);

      return {
        'success': true,
        'data': {'id': localId},
        'message': 'OTP entry imported successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to import OTP: $e'
      };
    }
  }

  /// Actualizar una entrada OTP
  Future<Map<String, dynamic>> updateOtpEntry(
    String id,
    Map<String, dynamic> entryData,
  ) async {
    try {
      final now = DateTime.now();
      
      final dataToUpdate = {
        ...entryData,
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'pending',
      };

      await _dbService.updateOtpEntry(id, dataToUpdate);

      return {
        'success': true,
        'message': 'OTP entry updated successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update OTP entry: $e'
      };
    }
  }

  /// Eliminar una entrada OTP
  Future<Map<String, dynamic>> deleteOtpEntry(String id) async {
    try {
      await _dbService.deleteOtpEntry(id);

      return {
        'success': true,
        'message': 'OTP entry deleted successfully'
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
      final allEntries = await _dbService.getAllOtpEntries();
        final entries = allEntries
          .map((data) => model.OtpEntry.fromJson(data))
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
}
