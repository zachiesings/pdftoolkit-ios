import 'package:flutter/material.dart';

/// Palet & tema aplikasi (desain premium 2026).
class C {
  static const bg = Color(0xFFF5F7FE);
  static const bgTop = Color(0xFFEEF2FF);
  static const card = Colors.white;
  static const ink = Color(0xFF15233B);
  static const muted = Color(0xFF6B7790);
  static const line = Color(0xFFE7ECF7);
  static const primary = Color(0xFF3B6EF5); // biru
  static const primary2 = Color(0xFF5B8DEF);
  static const indigo = Color(0xFF5B5BEF);
  static const violet = Color(0xFF7C5CF0);
  static const ok = Color(0xFF12A45A);
  static const danger = Color(0xFFE3503E);
  static const gold = Color(0xFFE9A23B);
}

/// Gradient hero / tombol utama.
const kHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF3B6EF5), Color(0xFF5B5BEF), Color(0xFF7C5CF0)],
);

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, colorSchemeSeed: C.primary);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: C.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: C.ink, fontWeight: FontWeight.w800, fontSize: 19),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: C.line,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.primary,
        side: const BorderSide(color: C.primary, width: 1.6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
  );
}

/// Dekorasi kartu standar (putih, sudut membulat, bayangan lembut).
BoxDecoration cardDeco({Color? border}) => BoxDecoration(
      color: C.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: border ?? C.line),
      boxShadow: const [BoxShadow(color: Color(0x141B2A4E), blurRadius: 26, offset: Offset(0, 14))],
    );

/// Latar gradient premium + dua cahaya lembut (blob). Pasang di belakang isi layar.
class PremiumBackground extends StatelessWidget {
  final Widget child;
  const PremiumBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [C.bgTop, C.bg],
            ),
          ),
        ),
      ),
      Positioned(top: -180, right: -160, child: _glow(420, C.violet)),
      Positioned(top: 120, left: -180, child: _glow(380, C.primary)),
      child,
    ]);
  }

  static Widget _glow(double size, Color color) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.0)]),
          ),
        ),
      );
}

/// Tombol gradient (aksi utama).
class GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  const GradientButton({super.key, required this.icon, required this.label, this.onPressed});
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: enabled ? kHeroGradient : null,
        color: enabled ? null : C.line,
        boxShadow: enabled
            ? const [BoxShadow(color: Color(0x553B6EF5), blurRadius: 22, offset: Offset(0, 10))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 17),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          ),
        ),
      ),
    );
  }
}
