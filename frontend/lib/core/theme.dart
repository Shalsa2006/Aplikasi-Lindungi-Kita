import 'package:flutter/material.dart';

class C {
  static const purple = Color(0xFF6C3FC5);
  static const violet = Color(0xFF8B5CF6);
  static const pink = Color(0xFFFF5C93);
  static const coral = Color(0xFFFF8A5B);
  static const teal = Color(0xFF12B5A6);
  static const blue = Color(0xFF3B82F6);
  static const indigo = Color(0xFF3730A3);
  static const yellow = Color(0xFFFFC857);
  static const green = Color(0xFF22A06B);
  static const red = Color(0xFFE5484D);
  static const bg = Color(0xFFF6F3FF);
  static const ink = Color(0xFF251B3D);
  static const muted = Color(0xFF7A7396);
  static const line = Color(0xFFE7E1F7);
}

const gMain = LinearGradient(colors: [C.purple, C.pink], begin: Alignment.topLeft, end: Alignment.bottomRight);
const gPetugas = LinearGradient(colors: [C.teal, C.blue], begin: Alignment.topLeft, end: Alignment.bottomRight);
const gAdmin = LinearGradient(colors: [C.indigo, C.violet], begin: Alignment.topLeft, end: Alignment.bottomRight);
const gSos = LinearGradient(colors: [C.red, C.coral], begin: Alignment.topLeft, end: Alignment.bottomRight);
const gWarm = LinearGradient(colors: [C.coral, C.yellow], begin: Alignment.topLeft, end: Alignment.bottomRight);

LinearGradient gradientFor(String? role) =>
    role == 'admin' ? gAdmin : (role == 'petugas' ? gPetugas : gMain);

ThemeData buildTheme() {
  final base = ColorScheme.fromSeed(seedColor: C.purple, brightness: Brightness.light);
  return ThemeData(
    useMaterial3: true,
    colorScheme: base.copyWith(primary: C.purple, secondary: C.pink),
    scaffoldBackgroundColor: C.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: C.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: C.ink, fontSize: 18, fontWeight: FontWeight.w800),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.purple, width: 2)),
      labelStyle: const TextStyle(color: C.muted),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: C.purple.withAlpha(40),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    ),
  );
}
