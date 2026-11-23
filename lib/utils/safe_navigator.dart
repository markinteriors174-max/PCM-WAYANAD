import 'package:flutter/material.dart';

/// Helper to safely execute Navigator pop operations without throwing '_history.isNotEmpty' assertion errors.
class SafeNavigator {
  /// Safely pops the current route if context is mounted and a route is available to pop.
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    if (!context.mounted) return;
    try {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop<T>(result);
        return;
      }
      final rootNav = Navigator.of(context, rootNavigator: true);
      if (rootNav.canPop()) {
        rootNav.pop<T>(result);
        return;
      }
    } catch (_) {}
  }

  /// Safely attempts to pop with maybePop.
  static Future<bool> maybePop<T extends Object?>(BuildContext context, [T? result]) async {
    if (!context.mounted) return false;
    try {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        return await nav.maybePop<T>(result);
      }
    } catch (_) {}
    return false;
  }
}

extension SafeNavigationContext on BuildContext {
  /// Extension method for context.safePop([result])
  void safePop<T extends Object?>([T? result]) {
    SafeNavigator.pop<T>(this, result);
  }

  /// Extension method for context.safeMaybePop([result])
  Future<bool> safeMaybePop<T extends Object?>([T? result]) async {
    return await SafeNavigator.maybePop<T>(this, result);
  }
}
