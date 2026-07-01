import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const _serif = 'SourceSerif4';
  static const _sans = 'Inter';

  static const largeTitle = TextStyle(
    fontFamily: _sans,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const title1 = TextStyle(
    fontFamily: _sans,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const title2 = TextStyle(
    fontFamily: _sans,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const title3 = TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  static const headline = TextStyle(
    fontFamily: _sans,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static const body = TextStyle(
    fontFamily: _serif,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.65,
  );

  static const bodySans = TextStyle(
    fontFamily: _sans,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.45,
  );

  static const callout = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static const subheadline = TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static const footnote = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static const caption1 = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.35,
  );

  static const caption2 = TextStyle(
    fontFamily: _sans,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );
}
