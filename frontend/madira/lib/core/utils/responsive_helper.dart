import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Compact desktop (small monitors, windowed mode)
  static bool isCompactDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024 &&
      MediaQuery.of(context).size.width < 1440;

  // Standard desktop (normal monitors)
  static bool isStandardDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1440 &&
      MediaQuery.of(context).size.width < 1920;

  // Large desktop (wide monitors)
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1920;

  static double getResponsivePadding(BuildContext context) {
    if (isCompactDesktop(context)) return 24;
    if (isStandardDesktop(context)) return 32;
    return 40;
  }

  static int getGridColumns(BuildContext context) {
    if (isCompactDesktop(context)) return 2;
    if (isStandardDesktop(context)) return 4;
    return 4;
  }

  static double getSidebarWidth(BuildContext context) {
    if (isCompactDesktop(context)) return 220;
    return 260;
  }

  static double getFontSize(BuildContext context, double baseSize) {
    if (isCompactDesktop(context)) return baseSize * 0.95;
    if (isLargeDesktop(context)) return baseSize * 1.05;
    return baseSize;
  }
}
