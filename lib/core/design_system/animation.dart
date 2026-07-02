import 'package:flutter/animation.dart';

class AppAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve sharpCurve = Curves.easeOutCubic;
  static const Curve springCurve = Curves.elasticOut;
}
