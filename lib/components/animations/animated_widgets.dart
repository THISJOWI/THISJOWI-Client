import 'package:flutter/material.dart';

/// Widget que anima sus hijos con un efecto staggered (secuencial)
class StaggeredAnimation extends StatelessWidget {
  final AnimationController controller;
  final List<Widget> children;
  final double initialDelay;
  final double staggerDelay;
  final double duration;
  final Axis direction;
  final double slideOffset;

  const StaggeredAnimation({
    super.key,
    required this.controller,
    required this.children,
    this.initialDelay = 0.0,
    this.staggerDelay = 0.1,
    this.duration = 0.4,
    this.direction = Axis.vertical,
    this.slideOffset = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final start = initialDelay + (index * staggerDelay);
        final end = start + duration;

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final animation = CurvedAnimation(
              parent: controller,
              curve: Interval(
                start.clamp(0.0, 1.0),
                end.clamp(0.0, 1.0),
                curve: Curves.easeOutCubic,
              ),
            );

            final opacity = Tween<double>(begin: 0.0, end: 1.0).evaluate(animation);
            final offset = Tween<double>(begin: slideOffset, end: 0.0).evaluate(animation);
            final scale = Tween<double>(begin: 0.9, end: 1.0).evaluate(animation);

            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: direction == Axis.vertical
                    ? Offset(0, offset)
                    : Offset(offset, 0),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

/// Widget que anima un solo elemento con fade + slide + scale
class FadeSlideScaleAnimation extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double slideOffset;
  final Axis direction;

  const FadeSlideScaleAnimation({
    super.key,
    required this.animation,
    required this.child,
    this.slideOffset = 30.0,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final opacity = Tween<double>(begin: 0.0, end: 1.0).evaluate(animation);
        final offset = Tween<double>(begin: slideOffset, end: 0.0).evaluate(animation);
        final scale = Tween<double>(begin: 0.95, end: 1.0).evaluate(animation);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: direction == Axis.vertical
                ? Offset(0, offset)
                : Offset(offset, 0),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Widget que anima con un efecto de pulso suave
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.minScale = 1.0,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Widget que anima con un efecto de rebote elastico
class ElasticScaleAnimation extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const ElasticScaleAnimation({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        ).value;

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Widget que anima con un efecto de rotacion suave
class RotateAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double beginAngle;
  final double endAngle;

  const RotateAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.beginAngle = 0.0,
    this.endAngle = 6.28319,
  });

  @override
  State<RotateAnimation> createState() => _RotateAnimationState();
}

class _RotateAnimationState extends State<RotateAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.beginAngle,
      end: widget.endAngle,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Widget que anima con un efecto de onda
class WaveAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double amplitude;

  const WaveAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.amplitude = 10.0,
  });

  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.amplitude * _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Widget que anima con un efecto de brillo/shimmer
class ShimmerAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color shimmerColor;

  const ShimmerAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.shimmerColor = Colors.white,
  });

  @override
  State<ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.transparent,
                widget.shimmerColor.withOpacity(0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
