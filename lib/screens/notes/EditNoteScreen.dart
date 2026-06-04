import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart' show Delta;
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
  late final QuillController _quillController;
  late final FocusNode _quillFocusNode;
  late final ScrollController _quillScrollController;
  StreamSubscription? _docSub;
  bool _isProcessing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _quillFocusNode = FocusNode();
    _quillScrollController = ScrollController();
    _quillController = _buildQuillController();
    _docSub = _quillController.document.changes.listen(_onDocChange);
  }

  QuillController _buildQuillController() {
    final note = widget.note;
    if (note == null) return QuillController.basic();

    final delta = Delta();

    if (note.content.isNotEmpty) {
      try {
        final json = jsonDecode(note.content);
        if (json is List) {
          final contentDelta = Delta.fromJson(json);
          final contentPlain = _deltaPlainText(contentDelta);
          if (note.title.isNotEmpty &&
              !contentPlain.startsWith(note.title)) {
            delta.insert('${note.title}\n', {'heading': 1});
          }
          delta.concat(contentDelta);
        } else {
          if (note.title.isNotEmpty) {
            delta.insert('${note.title}\n', {'heading': 1});
          }
          delta.insert(note.content);
        }
      } catch (_) {
        if (note.title.isNotEmpty) {
          delta.insert('${note.title}\n', {'heading': 1});
        }
        delta.insert(note.content);
      }
    } else if (note.title.isNotEmpty) {
      delta.insert('${note.title}\n', {'heading': 1});
      delta.insert('\n');
    } else {
      delta.insert('\n');
    }

    return QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  String _deltaPlainText(Delta delta) {
    final sb = StringBuffer();
    for (final op in delta.toJson()) {
      if (op['insert'] is String) {
        sb.write(op['insert'] as String);
      }
    }
    return sb.toString();
  }

  void _onDocChange(DocChange change) {
    if (_isProcessing) return;

    final ops = change.change.toJson();
    if (ops.length != 1) return;
    final insert = ops[0]['insert'];
    if (insert is! String || insert != ' ') return;

    _isProcessing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShortcut();
      _isProcessing = false;
    });
  }

  void _checkShortcut() {
    final offset = _quillController.selection.baseOffset;
    if (offset < 2) return;

    final text = _quillController.document.toPlainText();
    final before = text.substring(0, offset);

    for (final entry in _shortcuts) {
      final pattern = entry.$1;
      if (before.endsWith(pattern)) {
        _applyShortcut(pattern, entry.$2);
        return;
      }
    }
  }

  void _applyShortcut(String pattern, Attribute attr) {
    final offset = _quillController.selection.baseOffset;
    _quillController.replaceText(
        offset - pattern.length, pattern.length, '', null);
    _quillController.formatSelection(attr);
  }

  @override
  void dispose() {
    _docSub?.cancel();
    _quillController.dispose();
    _quillFocusNode.dispose();
    _quillScrollController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    final trimmed = _quillController.document.toPlainText().trimRight();
    if (trimmed.isEmpty) {
      if (!mounted) return;
      try {
        ErrorSnackBar.showWarning(context, 'Please enter a note'.i18n);
      } catch (e) {
        debugPrint('Error showing snackbar: $e');
      }
      return;
    }

    final lines = trimmed.split('\n');
    final title = lines.first.trim();
    final fullDelta = _quillController.document.toDelta();
    final titleLen = title.length + 1;

    Delta bodyDelta;
    if (_deltaLength(fullDelta) > titleLen) {
      bodyDelta = fullDelta.slice(titleLen);
    } else {
      bodyDelta = Delta()..insert('\n');
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final contentJson = jsonEncode(bodyDelta.toJson());

      final note = Note(
        title: title,
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

  int _deltaLength(Delta delta) {
    var len = 0;
    for (final op in delta.toJson()) {
      if (op['insert'] is String) {
        len += (op['insert'] as String).length;
      }
    }
    return len;
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
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: _quillController,
        config: QuillSimpleToolbarConfig(
          multiRowsDisplay: false,
          showDividers: false,
          showFontFamily: false,
          showFontSize: false,
          showSubscript: false,
          showSuperscript: false,
          showColorButton: false,
          showBackgroundColorButton: false,
          showCodeBlock: false,
          showLink: false,
          showSearchButton: false,
          showQuote: false,
          showIndent: false,
          showDirection: false,
          showLineHeightButton: false,
          showAlignmentButtons: false,
          showSmallButton: false,
          showStrikeThrough: false,
          showInlineCode: false,
          showUndo: true,
          showRedo: true,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showHeaderStyle: true,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: true,
          toolbarSectionSpacing: 2,
          buttonOptions: QuillSimpleToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              iconTheme: QuillIconTheme(
                iconButtonUnselectedData: const IconButtonData(
                  iconSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _shortcuts = <(String, Attribute)>[
  ('[] ', Attribute.unchecked),
  ('1. ', Attribute.ol),
  ('- ', Attribute.ul),
  ('# ', Attribute.h1),
  ('## ', Attribute.h2),
  ('### ', Attribute.h3),
];
