import 'package:flutter/material.dart';

class ThemeModeScope extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemeModeScope({
    super.key,
    required ValueNotifier<ThemeMode> notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static ValueNotifier<ThemeMode> of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeModeScope>();
    assert(scope != null, 'ThemeModeScope not found in widget tree.');
    return scope!.notifier!;
  }
}
