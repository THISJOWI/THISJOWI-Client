import 'package:flutter/material.dart';
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
  late final List<TextEditingController> _lineControllers = [];
  final _focusNode = FocusNode();
  bool _isLoading = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _loadContent(widget.note!.content);
    } else {
      _lineControllers.add(TextEditingController());
    }
  }

  void _loadContent(String content) {
    try {
      _lineControllers.clear();
      if (content.isEmpty) {
        _lineControllers.add(TextEditingController());
        return;
      }
      final lines = content.split('\n');
      for (String line in lines) {
        _lineControllers.add(TextEditingController(text: line));
      }
    } catch (e) {
      debugPrint('Error loading content: $e');
      _lineControllers.clear();
      _lineControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _lineControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    if (_titleController.text.isEmpty) {
      if (mounted) {
        try {
          ErrorSnackBar.showWarning(context, 'Please enter a title'.i18n);
        } catch (e) {
          debugPrint('Error showing snackbar: $e');
        }
      }
      return;
    }

    final contentText = _lineControllers.map((c) => c.text).join('\n').trim();
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
      final note = Note(
        title: _titleController.text.trim(),
        content: contentText,
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

  // Detectar el formato de la línea
  bool _isCheckboxLine(String line) {
    return line.startsWith('◯ ') || line.startsWith('✓ ');
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
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: TextFormField(
                          controller: _titleController,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _focusNode.requestFocus(),
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
                      ),
                      // ListView - cada línea con su TextField
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: _lineControllers.length,
                            itemBuilder: (context, index) {
                              final controller = _lineControllers[index];
                              final lineText = controller.text;
                              bool isCheckboxLine = _isCheckboxLine(lineText);
                              bool isChecked = lineText.startsWith('✓ ');

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Checkbox
                                  if (isCheckboxLine)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isChecked) {
                                            controller.text =
                                                '◯ ${lineText.substring(2)}';
                                          } else {
                                            controller.text =
                                                '✓ ${lineText.substring(2)}';
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 12.0, right: 8.0),
                                        child: Text(
                                          isChecked ? '✓' : '◯',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 0),
                                  // TextField
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      onChanged: (value) {
                                        setState(() {});
                                      },
                                      onSubmitted: (value) {
                                        // Solo crear nueva línea vacía
                                        if (index ==
                                            _lineControllers.length - 1) {
                                          setState(() {
                                            _lineControllers
                                                .add(TextEditingController());
                                          });

                                          Future.delayed(
                                              const Duration(milliseconds: 100),
                                              () {
                                            _scrollController.animateTo(
                                              _scrollController
                                                  .position.maxScrollExtent,
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              curve: Curves.easeOut,
                                            );
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        filled: false,
                                        fillColor: Colors.transparent,
                                        hintText: 'Start typing...'.i18n,
                                        hintStyle: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.3),
                                          fontSize: 16,
                                          height: 1.6,
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 16,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
