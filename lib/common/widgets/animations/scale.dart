import 'package:flutter/cupertino.dart';

///scale size

class ScaleWrapper extends StatefulWidget {
  final Widget child;
  final double startScale;
  final double endScale;
  final Duration duration;

  const ScaleWrapper({
    super.key,
    required this.child,
    this.startScale = 0.0,
    required this.endScale,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ScaleWrapper> createState() => _ScaleWrapperState();
}

class _ScaleWrapperState extends State<ScaleWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(
      begin: widget.startScale,
      end: widget.endScale,
    ).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      return ScaleTransition(
        scale: _animation,
        child: widget.child,
      );
    } else {
      return Transform.scale(
        scale: widget.endScale,
        child: widget.child,
      );
    }
  }
}

/// bouncing scale

class BounceScaleWidget extends StatefulWidget {
  final Widget child;
  final double startScale;
  final double endScale;
  final Duration duration;
  final Duration bounceDuration;

  const BounceScaleWidget({
    super.key,
    required this.child,
    this.startScale = 0.0,
    required this.endScale,
    this.duration = const Duration(milliseconds: 500),
    this.bounceDuration = const Duration(milliseconds: 200),
  });

  @override
  State<BounceScaleWidget> createState() => _BounceScaleWidgetState();
}

class _BounceScaleWidgetState extends State<BounceScaleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration + widget.bounceDuration,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.startScale, end: widget.endScale),
        weight: widget.duration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.endScale,
          end: widget.endScale * 0.95, // Slight bounce back
        ),
        weight: widget.bounceDuration.inMilliseconds.toDouble() / 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.endScale * 0.95,
          end: widget.endScale,
        ),
        weight: widget.bounceDuration.inMilliseconds.toDouble() / 2,
      ),
    ]).animate(_animationController);

    // Run the animation only once on the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
