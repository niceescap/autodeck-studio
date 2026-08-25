import "package:flutter/material.dart";

/// Thème AutoDeck Studio — sombre, sobre, accent doré.
///
/// Volontairement minimal (APIs stables uniquement) pour fiabiliser les
/// builds sur noe.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5E35B1),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF14121F),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
