import 'package:flutter/material.dart';

enum SlideDirection { up, down, left, right, start, end }

class SlideWrapper extends StatefulWidget {
  final Widget child;
  final double? initialOffset; // Offset in pixels
  final SlideDirection slideDirection;
  final Duration? duration;
  final Duration? startAnimationDelay;
  final Curve? curve;

  const SlideWrapper({
    super.key,
    required this.child,
    this.initialOffset = 20.0,
    this.curve,
    this.slideDirection = SlideDirection.left,
    this.duration = const Duration(milliseconds: 500),
    this.startAnimationDelay = Duration.zero,
  });

  @override
  _SlideWrapperState createState() => _SlideWrapperState();
}

class _SlideWrapperState extends State<SlideWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve ?? Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(widget.startAnimationDelay ?? Duration.zero, () {
        if (mounted) {
          _controller.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offset = widget.initialOffset ?? 20.0;
    double dx = 0.0, dy = 0.0;

    switch (widget.slideDirection) {
      case SlideDirection.up:
        dy = offset;
        break;
      case SlideDirection.down:
        dy = -offset;
        break;
      case SlideDirection.left:
        dx = offset;
        break;
      case SlideDirection.right:
        dx = -offset;
        break;
      case SlideDirection.start:
        dx =  -offset;
        break;
      case SlideDirection.end:
        dx =  offset;
        break;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(dx * _animation.value, dy * _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
