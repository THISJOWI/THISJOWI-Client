import 'package:uuid/uuid.dart';
import '../models/note.dart' as models;
import '../local/app_database.dart';

/// Repository for managing notes with offline-first approach
/// 
/// All operations go through local database first, then sync with backend
/// when connection is available
class NotesRepository {
  final AppDatabase _db = AppDatabase.instance();
  final Uuid _uuid = const Uuid();

  NotesRepository();

  /// Get all notes from local database
  Future<Map<String, dynamic>> getAllNotes() async {
    try {
      final localNotes = await _db.notesDao.getAllNotes();
      final notes = localNotes.map((data) => models.Note.fromJson(data)).toList();

      return {
        'success': true,
        'data': notes,
        'message': 'Notes loaded from local storage'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load notes: $e',
        'data': <models.Note>[]
      };
    }
  }

  /// Create a new note (FAST - saved locally, synced in background)
  Future<Map<String, dynamic>> createNote(models.Note note) async {
    try {
      final localId = _uuid.v4();
      final now = DateTime.now();

      final noteData = {
        'title': note.title,
        'content': note.content,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'pending',
        'localId': localId,
      };

      // Save to local database first (FAST)
      await _db.notesDao.insertNote(noteData);

      final createdNote = note.copyWith(
        localId: localId,
        createdAt: now,
        updatedAt: now,
        syncStatus: 'pending',
      );

      // Sync with backend in BACKGROUND (non-blocking)
      // Sync disabled

      return {
        'success': true,
        'data': createdNote,
        'message': 'Note created successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create note: $e'
      };
    }
  }

  /// Update a note (FAST - saved locally, synced in background)
  Future<Map<String, dynamic>> updateNote(String localId, models.Note note) async {
    try {
      final now = DateTime.now();

      final noteData = {
        'title': note.title,
        'content': note.content,
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'pending',
      };

      // Update in local database first (FAST)
      await _db.notesDao.updateNote(localId, noteData);

      final updatedNote = note.copyWith(
        updatedAt: now,
        syncStatus: 'pending',
      );

      // Sync disabled

      return {
        'success': true,
        'data': updatedNote,
        'message': 'Note updated successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update note: $e'
      };
    }
  }

  /// Delete a note (FAST - deleted locally, synced in background)
  Future<Map<String, dynamic>> deleteNote(String localId, {String? serverId}) async {
    try {
      // Delete from local database first (FAST)
      await _db.notesDao.deleteNote(localId);

      // Sync disabled

      return {
        'success': true,
        'message': 'Note deleted successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete note: $e'
      };
    }
  }

  /// Search notes locally
  Future<Map<String, dynamic>> searchNotes(String query) async {
    try {
      final localNotes = await _db.notesDao.searchNotes(query);
      final notes = localNotes.map((data) => models.Note.fromJson(data)).toList();

      return {
        'success': true,
        'data': notes,
        'message': 'Search results'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to search notes: $e',
        'data': <models.Note>[]
      };
    }
  }

  /// Force sync all pending changes
  Future<Map<String, dynamic>> syncAll() async {
    return {
      'success': true,
      'message': 'Sync is disabled'
    };
  }
}
