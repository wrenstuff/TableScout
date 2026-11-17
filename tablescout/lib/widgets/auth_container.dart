import 'package:flutter/material.dart';
import 'package:tablescout/theme/app_colours.dart';

class AuthContainer extends StatelessWidget {
  final Widget child;
  final double rightPadding;
  final double boxHeight;

  const AuthContainer({
    super.key,
    required this.child,
    this.rightPadding = 32,
    this.boxHeight = 650,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 500,
        height: boxHeight,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: 34,
            top: 32,
            bottom: 32,
            right: rightPadding,
          ),
          decoration: BoxDecoration(
            color: AppColours.primary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColours.accent, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
