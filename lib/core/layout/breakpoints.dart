import 'package:flutter/material.dart';

class Breakpoints {
  static const double compact = 600;
  static const double wide = 900;

  static bool isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < compact;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.of(context).size.width >= wide;
  }
}
