import 'package:flutter/material.dart';
import 'package:thisjowi/components/liquid_glass.dart';

class ExpandableActionButton extends StatefulWidget {
  final VoidCallback onCreatePassword;
  final VoidCallback onCreateNote;
  final VoidCallback? onCreateOtp;
  final VoidCallback? onCreateMessage;

  const ExpandableActionButton({
    super.key,
    required this.onCreatePassword,
    required this.onCreateNote,
    this.onCreateOtp,
    this.onCreateMessage,
  });

  @override
  State<ExpandableActionButton> createState() => _ExpandableActionButtonState();
}

class _ExpandableActionButtonState extends State<ExpandableActionButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _fadeAnimation;
  bool _isExpanded = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController!, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );
    _isInitialized = true;
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController?.forward();
      } else {
        _animationController?.reverse();
      }
    });
  }

  void _handleCreatePassword() {
    setState(() => _isExpanded = false);
    _animationController?.reverse();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) widget.onCreatePassword();
    });
  }

  void _handleCreateNote() {
    setState(() => _isExpanded = false);
    _animationController?.reverse();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) widget.onCreateNote();
    });
  }

  void _handleCreateOtp() {
    setState(() => _isExpanded = false);
    _animationController?.reverse();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && widget.onCreateOtp != null) widget.onCreateOtp!();
    });
  }

  Widget _buildOptionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required double bottomPadding,
  }) {
    if (_fadeAnimation == null || _scaleAnimation == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation!,
      child: ScaleTransition(
        scale: _scaleAnimation!,
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: LiquidGlass.container(
            context: context,
            blur: 15,
            opacity: 0.45,
            borderRadius: 24,
            padding: EdgeInsets.zero,
            tint: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                        size: 18),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    // Calculate vertical positions
    // Note: Items stack bottom-up. Lowest item (closest to main FAB) is last.
    // 60px height difference typical

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Option: Create OTP
        if (_isExpanded && widget.onCreateOtp != null)
          _buildOptionButton(
            onTap: _handleCreateOtp,
            icon: Icons.security_rounded,
            label: 'OTP',
            bottomPadding: 185.0,
          ),
        // Option: Create Password
        if (_isExpanded)
          _buildOptionButton(
            onTap: _handleCreatePassword,
            icon: Icons.key_rounded,
            label: 'Contraseña',
            bottomPadding: 130.0,
          ),
        // Option: Create Note
        if (_isExpanded)
          _buildOptionButton(
            onTap: _handleCreateNote,
            icon: Icons.description_outlined,
            label: 'Nota',
            bottomPadding: 75.0,
          ),
        // Main FAB button - Pill shape
        GestureDetector(
          onTap: _toggleExpand,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _isExpanded ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return LiquidGlass.container(
                context: context,
                blur: 10,
                opacity: 0.5,
                borderRadius: 28,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                tint: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: value * 0.785,
                      child: Icon(
                        _isExpanded ? Icons.close_rounded : Icons.add_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 22,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isExpanded ? 0 : 8,
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _isExpanded ? 0 : 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isExpanded ? 0 : null,
                        child: _isExpanded
                            ? const SizedBox.shrink()
                            : Text(
                                'Crear',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
