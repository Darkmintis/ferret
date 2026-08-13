import 'package:flutter/material.dart';

/// Host-app-independent theme for Ferret UI.
///
/// Always builds a fresh Material 3 [ThemeData] so host apps that set custom
/// fonts (Google Fonts, etc.) do not restyle the inspector.
abstract final class FerretTheme {
  static const Color seed = Color(0xFF1B6B4A);
  static const Color mint = Color(0xFF3DDC97);

  /// Slightly warm grey-white — easier on the eyes than pure white.
  static const Color lightBackground = Color(0xFFF6F7F8);

  static ThemeData of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = ColorScheme.fromSeed(
      seedColor: brightness == Brightness.dark ? mint : seed,
      brightness: brightness,
    );
    final background = brightness == Brightness.dark
        ? scheme.surface
        : lightBackground;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
          color: scheme.primary,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
    );
  }

  /// Wraps Ferret UI in an isolated theme.
  ///
  /// Pass a [builder] so `Theme.of(context)` inside resolves to Ferret, not
  /// the host app's fonts.
  static Widget wrap(BuildContext context, WidgetBuilder builder) {
    final theme = of(context);
    return Theme(
      data: theme,
      child: Builder(builder: builder),
    );
  }

  /// Branded app bar title with optional subtitle.
  static Widget brandTitle(BuildContext context, {String? subtitle}) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Ferret'),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
