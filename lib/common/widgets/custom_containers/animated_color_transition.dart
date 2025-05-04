import 'package:flutter/material.dart';

class AnimatedColorTransition extends StatefulWidget {
  final Color startColor;
  final Color endColor;
  final Curve curve;
  final Duration duration;
  final double? height, width;
  final Widget? child;

  const AnimatedColorTransition({
    super.key,
    this.startColor = Colors.blue,
    this.endColor = Colors.white,
    this.curve = Curves.easeInOut,
    this.duration = const Duration(milliseconds: 500),
    this.height,
    this.width,
    this.child,
  });

  @override
  _AnimatedColorTransitionState createState() =>
      _AnimatedColorTransitionState();
}

class _AnimatedColorTransitionState extends State<AnimatedColorTransition> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.startColor;

    Future.delayed(Duration.zero, () {
      setState(() {
        _currentColor = widget.endColor;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        color: _currentColor,
        height: widget.height,
        width: widget.width,
        child: widget.child,
      ),
    );
  }
}
