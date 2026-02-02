import 'package:flutter/widgets.dart';

class FoldDetector {
  static bool isCoverScreen(BuildContext context) {
    // Heuristic: Check for small width (compact size)
    // Most cover screens are narrow.
    final width = MediaQuery.of(context).size.width;
    return width < 350;
  }
}
