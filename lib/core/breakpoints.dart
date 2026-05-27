import 'package:flutter/material.dart';

/// Layout breakpoints aligned with Material adaptive guidance.
enum SeadsBreakpoint {
  /// Phone portrait, width < 600.
  compact,

  /// Large phone / tablet, 600 ≤ width < 1024.
  medium,

  /// Tablet landscape / desktop / web, width ≥ 1024.
  expanded,
}

abstract final class SeadsBreakpoints {
  static const double compactMax = 600;
  static const double mediumMax = 1024;

  static SeadsBreakpoint of(BuildContext context) {
    return ofWidth(MediaQuery.sizeOf(context).width);
  }

  static SeadsBreakpoint ofWidth(double width) {
    if (width >= mediumMax) return SeadsBreakpoint.expanded;
    if (width >= compactMax) return SeadsBreakpoint.medium;
    return SeadsBreakpoint.compact;
  }

  static bool isCompact(BuildContext context) => of(context) == SeadsBreakpoint.compact;
  static bool isMediumOrWider(BuildContext context) => of(context) != SeadsBreakpoint.compact;
  static bool isExpanded(BuildContext context) => of(context) == SeadsBreakpoint.expanded;
}
