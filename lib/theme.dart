import 'package:flutter/material.dart';

/// Palet & tema aplikasi.
class C {
  static const bg = Color(0xFFF4F6FB);
  static const card = Colors.white;
  static const ink = Color(0xFF15233B);
  static const muted = Color(0xFF6B7790);
  static const line = Color(0xFFE3E8F2);
  static const primary = Color(0xFF3B6EF5); // biru
  static const primary2 = Color(0xFF5B8DEF);
  static const ok = Color(0xFF12A45A);
  static const danger = Color(0xFFE3503E);
  static const gold = Color(0xFFE9A23B);
}

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, colorSchemeSeed: C.primary);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: C.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: C.ink, fontWeight: FontWeight.w800, fontSize: 18),
    ),
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
  );
}

/// Dekorasi kartu standar.
BoxDecoration cardDeco({Color? border}) => BoxDecoration(
      color: C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border ?? C.line),
      boxShadow: const [BoxShadow(color: Color(0x0F1B2A4E), blurRadius: 14, offset: Offset(0, 6))],
    );
