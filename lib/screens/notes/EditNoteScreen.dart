import 'package:flutter/material.dart';
import 'package:thisjowi/components/errorBar.dart';
import 'package:thisjowi/data/models/noteEntry.dart';
import 'package:thisjowi/i18n/translationService.dart';

import '../../core/appColors.dart';
import '../../data/repository/notes_repository.dart';
import '../../i18n/translations.dart';

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
      ErrorSnackBar.showWarning(context, 'Please enter a title'.i18n);
      return;
    }

    final contentText = _lineControllers.map((c) => c.text).join('\n').trim();
    if (contentText.isEmpty) {
      ErrorSnackBar.showWarning(context, 'Please enter the content'.i18n);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final note = Note(
        title: _titleController.text.trim(),
        content: contentText,
      );

      if (widget.note != null) {
        await widget.notesRepository
            .updateNote(widget.note!.localId ?? '', note);
      } else {
        await widget.notesRepository.createNote(note);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving note: $e');
      if (mounted) {
        ErrorSnackBar.show(context, 'Error saving note'.i18n);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: AppColors.text, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 50,
        title: null,
        toolbarHeight: 70,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isLoading ? null : _saveNote,
              child: Text(
                'Done'.tr(context),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TextFormField(
                      controller: _titleController,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _focusNode.requestFocus(),
                      decoration: InputDecoration(
                        hintText: 'Title'.i18n,
                        hintStyle: TextStyle(
                          color: AppColors.text.withOpacity(0.3),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ListView - cada línea con su TextField
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ListView.builder(
                        controller: _scrollController,
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
                                        color: AppColors.text,
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
                                    if (index == _lineControllers.length - 1) {
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
                                          duration:
                                              const Duration(milliseconds: 200),
                                          curve: Curves.easeOut,
                                        );
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Start typing...',
                                    hintStyle: TextStyle(
                                      color: AppColors.text.withOpacity(0.3),
                                      fontSize: 16,
                                      height: 1.6,
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.text,
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
    );
  }
}
