import 'package:flutter/material.dart';

class DynamicContainer extends StatefulWidget {
  final Decoration? decoration;
  final Duration? duration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Widget child;
  final Curve? curve;
  final bool showChild;

  const DynamicContainer({
    super.key,
    this.decoration,
    this.duration,
    this.padding,
    this.margin,
    this.curve,
    required this.child, this.showChild = true,
  });

  @override
  _DynamicContainerState createState() => _DynamicContainerState();
}

class _DynamicContainerState extends State<DynamicContainer>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: AnimatedSize(
        duration: widget.duration ?? const Duration(milliseconds: 600),
        curve:widget.curve ?? Curves.easeOutBack,
        child: Container(
          decoration: widget.decoration,
          padding: widget.padding ?? EdgeInsets.zero,
          child: widget.showChild ? widget.child : SizedBox.shrink(),
        ),
      ),
    );
  }
}
