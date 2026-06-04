import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/data/models/note_entry.dart';
import 'package:thisjowi/i18n/translations.dart';

import '../../data/repository/notes_repository.dart';

class EditNoteScreen extends StatefulWidget {
  final NotesRepository notesRepository;
  final Note? note;

  const EditNoteScreen({
    super.key,
    required this.notesRepository,
    this.note,
  });

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _titleController = TextEditingController();
  late final QuillController _quillController;
  late final FocusNode _quillFocusNode;
  late final ScrollController _quillScrollController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _quillFocusNode = FocusNode();
    _quillScrollController = ScrollController();

    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _quillController = _buildQuillController(widget.note!.content);
    } else {
      _quillController = QuillController.basic();
    }
  }

  QuillController _buildQuillController(String content) {
    if (content.isEmpty) return QuillController.basic();

    try {
      final json = jsonDecode(content);
      if (json is List) {
        return QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (_) {}

    final doc = Document();
    final text = content.replaceAll('\n', '\n');
    if (text.isNotEmpty) {
      doc.insert(0, text);
    }
    return QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _quillFocusNode.dispose();
    _quillScrollController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      if (mounted) {
        try {
          ErrorSnackBar.showWarning(context, 'Please enter a title'.i18n);
        } catch (e) {
          debugPrint('Error showing snackbar: $e');
        }
      }
      return;
    }

    final contentText = _quillController.document.toPlainText().trim();
    if (contentText.isEmpty) {
      if (!mounted) return;
      try {
        ErrorSnackBar.showWarning(context, 'Please enter the content'.i18n);
      } catch (e) {
        debugPrint('Error showing snackbar: $e');
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final contentJson =
          jsonEncode(_quillController.document.toDelta().toJson());

      final note = Note(
        title: _titleController.text.trim(),
        content: contentJson,
        id: widget.note?.id,
        localId: widget.note?.localId,
        serverId: widget.note?.serverId,
      );

      if (widget.note != null) {
        await widget.notesRepository
            .updateNote(widget.note!.localId ?? '', note);
      } else {
        await widget.notesRepository.createNote(note);
      }

      if (!mounted) return;

      try {
        Navigator.pop(context, true);
      } catch (e) {
        debugPrint('Error closing dialog: $e');
      }
    } catch (e) {
      debugPrint('Error saving note: $e');
      if (mounted) {
        try {
          ErrorSnackBar.show(context, 'Error saving note'.i18n);
        } catch (snackBarError) {
          debugPrint('Error showing snackbar: $snackBarError');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _isLoading ? null : _saveNote,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Text(
                        'Done'.i18n,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _quillFocusNode.requestFocus(),
                          decoration: InputDecoration(
                            hintText: 'Title'.i18n,
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.3),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: QuillEditor.basic(
                            controller: _quillController,
                            focusNode: _quillFocusNode,
                            scrollController: _quillScrollController,
                            config: const QuillEditorConfig(
                              placeholder: 'Start typing...',
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: _quillController,
        config: const QuillSimpleToolbarConfig(
          showSearchButton: false,
          showFontFamily: false,
          showFontSize: false,
          showSubscript: false,
          showSuperscript: false,
          showColorButton: false,
          showBackgroundColorButton: false,
          showCodeBlock: false,
          showLink: false,
          showQuote: true,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: true,
          showHeaderStyle: true,
          showIndent: false,
          showDirection: false,
          showLineHeightButton: false,
          showAlignmentButtons: false,
          showSmallButton: false,
          multiRowsDisplay: false,
        ),
      ),
    );
  }
}
