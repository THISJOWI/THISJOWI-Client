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
  bool _titleFormatted = false;

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

    try {
      if (note.content.isNotEmpty) {
        final json = jsonDecode(note.content);
        if (json is List && json.isNotEmpty) {
          final delta = Delta.fromJson(json);
          final plain = _plainText(delta);
          if (plain.trimRight().isNotEmpty) {
            final controller = QuillController(
              document: Document.fromDelta(delta),
              selection: TextSelection.collapsed(
                  offset: plain.indexOf('\n') + 1),
            );
            _formatTitle(controller, plain);
            return controller;
          }
        }
      }
    } catch (_) {
      if (note.content.trim().isNotEmpty) {
        final delta = Delta();
        if (note.title.isNotEmpty) {
          delta.insert('${note.title}\n');
        }
        delta.insert(note.content);
        if (!note.content.endsWith('\n')) {
          delta.insert('\n');
        }
        final controller = QuillController(
          document: Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
        _formatTitle(controller, _plainText(delta));
        return controller;
      }
    }

    final delta = Delta();
    delta.insert('${note.title}\n');
    delta.insert('\n');
    final controller = QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _formatTitle(controller, '${note.title}\n');
    return controller;
  }

  String _plainText(Delta delta) {
    final sb = StringBuffer();
    for (final op in delta.toJson()) {
      if (op['insert'] is String) sb.write(op['insert'] as String);
    }
    return sb.toString();
  }

  void _formatTitle(QuillController controller, String plain) {
    final idx = plain.indexOf('\n');
    if (idx > 0) {
      controller.formatText(0, idx, Attribute.h1);
    }
    _titleFormatted = true;
  }

  void _onDocChange(DocChange change) {
    if (_isProcessing) return;

    if (!_titleFormatted) {
      _checkAndFormatTitle();
      return;
    }

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

  void _checkAndFormatTitle() {
    if (_titleFormatted) return;
    _titleFormatted = true;
    final plain = _quillController.document.toPlainText();
    final idx = plain.indexOf('\n');
    if (idx > 0) {
      _quillController.formatText(0, idx, Attribute.h1);
    }
  }

  void _checkShortcut() {
    final offset = _quillController.selection.baseOffset;
    if (offset < 2) return;

    final text = _quillController.document.toPlainText();
    final before = text.substring(0, offset);

    for (final entry in _shortcuts) {
      if (before.endsWith(entry.$1)) {
        _applyShortcut(entry.$1, entry.$2);
        return;
      }
    }
  }

  void _applyShortcut(String pattern, Attribute attr) {
    final offset = _quillController.selection.baseOffset;
    final start = offset - pattern.length;
    _quillController.replaceText(start, pattern.length, '\n', null);
    _quillController.replaceText(
        0, 0, '', TextSelection.collapsed(offset: start));
    _quillController.formatText(0, 0, attr);
    _quillController.replaceText(start + 1, 1, '', null);
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
    final plain = _quillController.document.toPlainText().trimRight();
    if (plain.isEmpty) {
      if (!mounted) return;
      try {
        ErrorSnackBar.showWarning(context, 'Please enter a note'.i18n);
      } catch (e) {
        debugPrint('Error showing snackbar: $e');
      }
      return;
    }

    final title = plain.split('\n').first.trim();
    final contentJson =
        jsonEncode(_quillController.document.toDelta().toJson());

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveOnBack() async {
    final plain = _quillController.document.toPlainText().trimRight();
    if (plain.isEmpty) return;

    final title = plain.split('\n').first.trim();
    final contentJson =
        jsonEncode(_quillController.document.toDelta().toJson());

    try {
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
    } catch (e) {
      debugPrint('Error saving note on back: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveOnBack();
        if (mounted) Navigator.of(context).pop(true);
      },
      child: Scaffold(
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
                    onPressed: () {
                      _saveOnBack().then((_) {
                        if (mounted) Navigator.pop(context, true);
                      });
                    },
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
