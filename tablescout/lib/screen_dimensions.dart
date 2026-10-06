import 'package:flutter/material.dart';

const double mobileBreakpoint = 600;

class ScreenDimensions {
  // Checks screen size. If it's less than mobile breakpoint,
  // then it will return true. Otherwise false.
  static bool isMobile(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < mobileBreakpoint) {
      return true;
    } else {
      return false;
    }
  }
}