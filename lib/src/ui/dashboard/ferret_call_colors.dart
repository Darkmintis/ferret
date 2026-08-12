import 'package:flutter/material.dart';

/// Shared HTTP method / status colors for call list UI.
abstract final class FerretCallColors {
  static Color methodColor(String method, ColorScheme scheme) {
    return switch (method.toUpperCase()) {
      'GET' => scheme.primary,
      'POST' => const Color(0xFF1565C0),
      'PUT' => const Color(0xFFEF6C00),
      'PATCH' => const Color(0xFF6A1B9A),
      'DELETE' => scheme.error,
      _ => scheme.secondary,
    };
  }

  static Color statusColor(int code, ColorScheme scheme) {
    if (code >= 200 && code < 300) return const Color(0xFF1B6B4A);
    if (code >= 300 && code < 400) return const Color(0xFF1565C0);
    if (code >= 400 && code < 500) return const Color(0xFFEF6C00);
    if (code >= 500) return scheme.error;
    return scheme.onSurface;
  }
}
