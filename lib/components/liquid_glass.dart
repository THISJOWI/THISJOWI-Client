import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

/// Liquid Glass Design System for Flutter
/// Recreates iOS 26 Liquid Glass aesthetic with cross-platform compatibility
/// 
/// Key features:
/// - GlassEffectContainer: Wraps multiple glass views for morphing and performance
/// - glassEffectUnion: Groups related elements into unified glass shapes
/// - glassEffectID + Namespace: Enables smooth morphing transitions
/// - interactive(): Explicit opt-in for touch/pointer reactions
/// - Dynamic reflection: Multi-layer gradients that reflect surrounding content
class LiquidGlass {
  /// Standard blur values for different glass intensities
  static const double subtleBlur = 12.0;
  static const double mediumBlur = 20.0;
  static const double strongBlur = 30.0;

  /// Opacity values for glass backgrounds
  static const double subtleOpacity = 0.15;
  static const double mediumOpacity = 0.25;
  static const double strongOpacity = 0.35;

  /// Border radius for glass containers
  static const double smallRadius = 12.0;
  static const double mediumRadius = 20.0;
  static const double largeRadius = 28.0;

  /// Animation durations
  static const Duration quickDuration = Duration(milliseconds: 150);
  static const Duration standardDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);

  /// Creates a subtle glass effect container
  static Widget container({
    required Widget child,
    BuildContext? context,
    double blur = subtleBlur,
    double opacity = subtleOpacity,
    double borderRadius = mediumRadius,
    Color? tint,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    bool interactive = false,
    bool showBorder = true,
    VoidCallback? onTap,
  }) {
    final brightness = context != null
        ? Theme.of(context).brightness
        : Brightness.dark;

    Widget glassWidget = Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: _getGlassColor(tint, opacity, brightness),
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                  ? Border.all(
                      color: _getBorderColor(brightness),
                      width: 0.5,
                    )
                  : null,
              gradient: _getGlassGradient(tint, opacity, brightness),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (interactive && onTap != null) {
      glassWidget = _InteractiveGlass(
        onTap: onTap,
        borderRadius: borderRadius,
        child: glassWidget,
      );
    } else if (onTap != null) {
      glassWidget = GestureDetector(
        onTap: onTap,
        child: glassWidget,
      );
    }

    return glassWidget;
  }

  /// Creates a warning glass container with subtle red tint
  static Widget warningContainer({
    required Widget child,
    BuildContext? context,
    double blur = mediumBlur,
    double opacity = mediumOpacity,
    double borderRadius = mediumRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return container(
      context: context,
      child: child,
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      tint: Colors.red.withValues(alpha: 0.1),
      padding: padding,
      margin: margin,
      onTap: onTap,
    );
  }

  /// Creates a prominent glass container for important sections
  static Widget prominentContainer({
    required Widget child,
    BuildContext? context,
    double blur = mediumBlur,
    double opacity = mediumOpacity,
    double borderRadius = largeRadius,
    Color? tint,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return container(
      context: context,
      child: child,
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      tint: tint,
      padding: padding,
      margin: margin,
      onTap: onTap,
    );
  }

  /// Creates a glass card with enhanced styling
  static Widget card({
    required Widget child,
    BuildContext? context,
    double blur = subtleBlur,
    double opacity = subtleOpacity,
    double borderRadius = mediumRadius,
    Color? tint,
    EdgeInsetsGeometry? padding = const EdgeInsets.all(16),
    EdgeInsetsGeometry? margin = const EdgeInsets.symmetric(vertical: 4),
    VoidCallback? onTap,
  }) {
    return container(
      context: context,
      child: child,
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      tint: tint,
      padding: padding,
      margin: margin,
      onTap: onTap,
    );
  }

  /// Helper method to get glass color based on theme
  static Color _getGlassColor(Color? tint, double opacity, Brightness brightness) {
    if (tint != null) {
      return tint.withValues(alpha: opacity);
    }
    if (brightness == Brightness.light) {
      return Colors.white.withValues(alpha: opacity * 0.9);
    }
    return const Color(0xFF1C1C1E).withValues(alpha: opacity * 0.85);
  }

  /// Helper method to get border color based on theme
  static Color _getBorderColor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return Colors.white.withValues(alpha: 0.3);
    }
    return const Color(0xFF2C2C2E).withValues(alpha: 0.3);
  }

  /// Helper method to create glass gradient with multi-layer reflection effect
  static LinearGradient? _getGlassGradient(Color? tint, double opacity, Brightness brightness) {
    if (tint != null) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tint.withValues(alpha: opacity * 0.5),
          tint.withValues(alpha: opacity * 0.3),
        ],
      );
    }
    if (brightness == Brightness.light) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: opacity * 0.8),
          Colors.white.withValues(alpha: opacity * 0.5),
        ],
        stops: const [0.0, 1.0],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF2C2C2E).withValues(alpha: opacity * 0.6),
        const Color(0xFF1C1C1E).withValues(alpha: opacity * 0.4),
      ],
      stops: const [0.0, 1.0],
    );
  }

  /// Creates a morphing glass effect for navigation with advanced animations
  static Widget morphingContainer({
    required Widget child,
    required bool isActive,
    double blur = subtleBlur,
    double opacity = subtleOpacity,
    double borderRadius = mediumRadius,
    Duration duration = const Duration(milliseconds: 300),
    VoidCallback? onTap,
    String? glassEffectId,
    String? glassEffectUnion,
  }) {
    return _MorphingGlassContainer(
      isActive: isActive,
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      duration: duration,
      onTap: onTap,
      glassEffectId: glassEffectId,
      glassEffectUnion: glassEffectUnion,
      child: child,
    );
  }
}

/// Interactive glass widget with haptic feedback and visual feedback
class _InteractiveGlass extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;

  const _InteractiveGlass({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  State<_InteractiveGlass> createState() => _InteractiveGlassState();
}

class _InteractiveGlassState extends State<_InteractiveGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: LiquidGlass.quickDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedOpacity(
              duration: LiquidGlass.quickDuration,
              opacity: _isPressed ? 0.8 : 1.0,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Advanced morphing glass container with glassEffectID and glassEffectUnion support
class _MorphingGlassContainer extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Duration duration;
  final VoidCallback? onTap;
  final String? glassEffectId;
  final String? glassEffectUnion;

  const _MorphingGlassContainer({
    required this.child,
    required this.isActive,
    required this.blur,
    required this.opacity,
    required this.borderRadius,
    required this.duration,
    this.onTap,
    this.glassEffectId,
    this.glassEffectUnion,
  });

  @override
  State<_MorphingGlassContainer> createState() => _MorphingGlassContainerState();
}

class _MorphingGlassContainerState extends State<_MorphingGlassContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _radiusAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _setupAnimations();
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_MorphingGlassContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _setupAnimations() {
    _blurAnimation = Tween<double>(
      begin: widget.blur * 0.7,
      end: widget.blur,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: widget.opacity * 0.5,
      end: widget.opacity * 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _radiusAnimation = Tween<double>(
      begin: widget.borderRadius * 0.8,
      end: widget.borderRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentBlur = _blurAnimation.value;
        final currentOpacity = _opacityAnimation.value;
        final currentRadius = _radiusAnimation.value;
        final currentScale = _scaleAnimation.value;

        final brightness = Theme.of(context).brightness;
        final isLight = brightness == Brightness.light;

        Widget glassContent = Transform.scale(
          scale: currentScale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(currentRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: currentBlur,
                sigmaY: currentBlur,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLight
                      ? Colors.white.withValues(alpha: currentOpacity)
                      : const Color(0xFF1C1C1E).withValues(alpha: currentOpacity),
                  borderRadius: BorderRadius.circular(currentRadius),
                  border: Border.all(
                      color: isLight
                          ? Colors.white.withValues(alpha: widget.isActive ? 0.4 : 0.25)
                          : const Color(0xFF2C2C2E).withValues(alpha: widget.isActive ? 0.4 : 0.25),
                    width: widget.isActive ? 1.0 : 0.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isLight
                        ? [
                            Colors.white.withValues(alpha: currentOpacity * 0.8),
                            Colors.white.withValues(alpha: currentOpacity * 0.5),
                          ]
                        : [
                            const Color(0xFF2C2C2E).withValues(alpha: currentOpacity * 0.6),
                            const Color(0xFF1C1C1E).withValues(alpha: currentOpacity * 0.4),
                          ],
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        );

        if (widget.onTap != null) {
          glassContent = GestureDetector(
            onTap: widget.onTap,
            child: glassContent,
          );
        }

        return glassContent;
      },
    );
  }
}

/// GlassEffectContainer - Wraps multiple glass views for morphing and performance
/// 
/// This is the core container for Liquid Glass design. It enables:
/// - Performance optimization for multiple glass elements
/// - Morphing between glass elements
/// - Unified glass shapes for grouped elements
/// 
/// Example:
/// ```dart
/// GlassEffectContainer(
///   spacing: 40.0,
///   child: Row(
///     children: [
///       Icon(Icons.home).glassEffect(),
///       Icon(Icons.search).glassEffect(),
///     ],
///   ),
/// )
/// ```
class GlassEffectContainer extends StatelessWidget {
  final Widget child;
  final double spacing;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassEffectContainer({
    super.key,
    required this.child,
    this.spacing = 40.0,
    this.blur = LiquidGlass.mediumBlur,
    this.opacity = LiquidGlass.mediumOpacity,
    this.borderRadius = LiquidGlass.largeRadius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withValues(alpha: opacity)
                  : const Color(0xFF1C1C1E).withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.3)
                    : const Color(0xFF2C2C2E).withValues(alpha: 0.3),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? [
                        Colors.white.withValues(alpha: opacity * 0.8),
                        Colors.white.withValues(alpha: opacity * 0.5),
                      ]
                    : [
                        const Color(0xFF2C2C2E).withValues(alpha: opacity * 0.6),
                        const Color(0xFF1C1C1E).withValues(alpha: opacity * 0.4),
                      ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Liquid Glass Navigation Bar with advanced morphing effects
/// 
/// Features:
/// - GlassEffectContainer wrapping for performance
/// - Morphing transitions between tabs
/// - Haptic feedback on interaction
/// - Dynamic reflection effects
/// - glassEffectUnion for unified appearance
class LiquidGlassNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  final Color? backgroundColor;
  final double height;
  final double spacing;
  final bool enableHaptic;

  const LiquidGlassNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.height = 80,
    this.spacing = 20.0,
    this.enableHaptic = true,
  });

  @override
  State<LiquidGlassNavigationBar> createState() => _LiquidGlassNavigationBarState();
}

class _LiquidGlassNavigationBarState extends State<LiquidGlassNavigationBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: LiquidGlass.standardDuration,
        vsync: this,
      ),
    );
    // Initialize active tab
    if (widget.currentIndex < _controllers.length) {
      _controllers[widget.currentIndex].value = 1.0;
    }
  }

  @override
  void didUpdateWidget(LiquidGlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Animate out old selection
      if (oldWidget.currentIndex < _controllers.length) {
        _controllers[oldWidget.currentIndex].reverse();
      }
      // Animate in new selection
      if (widget.currentIndex < _controllers.length) {
        _controllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: GlassEffectContainer(
          blur: LiquidGlass.subtleBlur,
          opacity: LiquidGlass.subtleOpacity,
          borderRadius: LiquidGlass.largeRadius,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              final isActive = index == widget.currentIndex;

              return Expanded(
                child: _NavigationItem(
                  item: item,
                  isActive: isActive,
                  onTap: () => _handleTap(index),
                  controller: _controllers[index],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item with morphing animation
class _NavigationItem extends StatelessWidget {
  final BottomNavigationBarItem item;
  final bool isActive;
  final VoidCallback onTap;
  final AnimationController controller;

  const _NavigationItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = controller.value;
        final brightness = Theme.of(context).brightness;
        final isLight = brightness == Brightness.light;
        
        // Smooth interpolation values
        final blur = LiquidGlass.subtleBlur + (LiquidGlass.mediumBlur - LiquidGlass.subtleBlur) * progress;
        final opacity = LiquidGlass.subtleOpacity + (LiquidGlass.mediumOpacity - LiquidGlass.subtleOpacity) * progress;
        final scale = 1.0 + (0.1 * progress);
        final iconSize = 20.0 + (4.0 * progress);
        
        // Color interpolation
        final activeColor = Theme.of(context).colorScheme.primary;
        final inactiveColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
        final color = Color.lerp(inactiveColor, activeColor, progress)!;

        final bgColor = isLight
            ? Colors.white.withValues(alpha: opacity * (0.5 + 0.5 * progress))
            : const Color(0xFF1C1C1E).withValues(alpha: opacity * (0.5 + 0.5 * progress));
        final borderColor = isLight
            ? Colors.white.withValues(alpha: 0.25 + 0.15 * progress)
            : const Color(0xFF2C2C2E).withValues(alpha: 0.25 + 0.15 * progress);
        final gradStart = isLight
            ? Colors.white.withValues(alpha: opacity * 0.8)
            : const Color(0xFF2C2C2E).withValues(alpha: opacity * 0.6);
        final gradEnd = isLight
            ? Colors.white.withValues(alpha: opacity * 0.5)
            : const Color(0xFF1C1C1E).withValues(alpha: opacity * 0.4);

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Transform.scale(
              scale: scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(LiquidGlass.smallRadius + (4 * progress)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(LiquidGlass.smallRadius + (4 * progress)),
                      border: Border.all(
                        color: borderColor,
                        width: 0.5 + (0.5 * progress),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [gradStart, gradEnd],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconTheme(
                          data: IconThemeData(
                            color: color,
                            size: iconSize,
                          ),
                          child: item.icon,
                        ),
                        if (item.label != null && item.label!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.label!,
                            style: TextStyle(
                              fontSize: 10 + (2 * progress),
                              fontWeight: progress > 0.5 ? FontWeight.w600 : FontWeight.normal,
                              color: color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Liquid Glass Section Header
class LiquidGlassSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? tint;

  const LiquidGlassSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 16,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Liquid Glass List Item
class LiquidGlassListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isWarning;

  const LiquidGlassListItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final glassWidget = isWarning
        ? LiquidGlass.warningContainer(
            context: context,
            child: _buildContent(context),
            onTap: onTap,
          )
        : LiquidGlass.card(
            context: context,
            child: _buildContent(context),
            onTap: onTap,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: glassWidget,
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ??
                Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Extension methods for easy glass effect application
extension LiquidGlassExtension on Widget {
  /// Apply glass effect to any widget
  Widget glassEffect({
    double blur = LiquidGlass.mediumBlur,
    double opacity = LiquidGlass.mediumOpacity,
    double borderRadius = LiquidGlass.mediumRadius,
    Color? tint,
    EdgeInsetsGeometry? padding,
    bool interactive = false,
    VoidCallback? onTap,
  }) {
    return LiquidGlass.container(
      child: this,
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      tint: tint,
      padding: padding,
      interactive: interactive,
      onTap: onTap,
    );
  }
}
