import 'package:flutter/material.dart';
import '../core/appColors.dart';

class ExpandableActionButton extends StatefulWidget {
  final VoidCallback onCreatePassword;
  final VoidCallback onCreateNote;

  const ExpandableActionButton({
    super.key,
    required this.onCreatePassword,
    required this.onCreateNote,
  });

  @override
  State<ExpandableActionButton> createState() => _ExpandableActionButtonState();
}

class _ExpandableActionButtonState extends State<ExpandableActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleCreatePassword() {
    // Collapse the menu first
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();
    // Then execute the action
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.onCreatePassword();
      }
    });
  }

  void _handleCreateNote() {
    // Collapse the menu first
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();
    // Then execute the action
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.onCreateNote();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Option: Create Password (when expanded)
        if (_isExpanded)
          ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 130.0, right: 0.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.text.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleCreatePassword,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.lock_open,
                        color: AppColors.background,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Option: Create Note (when expanded)
        if (_isExpanded)
          ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 70.0, right: 0.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.text.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleCreateNote,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.note_add,
                        color: AppColors.background,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Main button that expands/collapses
        Container(
          decoration: BoxDecoration(
            color: AppColors.text,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpand,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 0.785,
                      child: Icon(
                        Icons.add,
                        color: AppColors.background,
                        size: 28,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}