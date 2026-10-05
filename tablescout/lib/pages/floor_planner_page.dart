import 'package:flutter/material.dart';

class FloorPlanner extends StatefulWidget {
  const FloorPlanner({super.key});

  @override
  State<FloorPlanner> createState() => _FloorPlannerState();
}

class _FloorPlannerState extends State<FloorPlanner> {
  static const double outerPadding = 20;
  static const double toolbarWidth = 200;
  static const double bottomToolbarHeight = 100;
  static const double toolbarGap = 20;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Stack(
        children: [
          // Left toolbar
          Positioned(
            left: outerPadding,
            top: outerPadding,
            bottom: outerPadding,
            width: toolbarWidth,
            child: Container(
              color: Colors.grey.shade400,
              child: const Center(
                child: Text('Left Toolbar'),
              ),
            ),
          ),

          // Right toolbar
          Positioned(
            right: outerPadding,
            top: outerPadding,
            bottom: outerPadding,
            width: toolbarWidth,
            child: Container(
              color: Colors.grey.shade400,
              child: const Center(
                child: Text('Right Toolbar'),
              ),
            ),
          ),

          // Bottom toolbar: fits between the side toolbars
          Positioned(
            left: outerPadding + toolbarWidth + toolbarGap,
            right: outerPadding + toolbarWidth + toolbarGap,
            bottom: outerPadding,
            height: bottomToolbarHeight,
            child: Container(
              color: Colors.grey.shade400,
              child: const Center(
                child: Text('Bottom Toolbar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}