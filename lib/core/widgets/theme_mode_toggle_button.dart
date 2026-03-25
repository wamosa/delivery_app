import 'package:flutter/material.dart';

import '../theme/theme_mode_scope.dart';

class ThemeModeToggleButton extends StatelessWidget {
  const ThemeModeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = ThemeModeScope.of(context);
    final isDark = themeMode.value == ThemeMode.dark;

    return IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
      onPressed: () {
        themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
      },
    );
  }
}
