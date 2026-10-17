import 'package:flutter/material.dart';

/// Colores del semáforo (favorable, neutral, desfavorable, sin dato). Viven
/// en el tema para que el claro y el oscuro mantengan el contraste de texto
/// (4,5:1) sin repetir valores en los widgets.
@immutable
class SignalColors extends ThemeExtension<SignalColors> {
  const SignalColors({
    required this.favorable,
    required this.neutral,
    required this.unfavorable,
    required this.unknown,
  });

  final Color favorable;
  final Color neutral;
  final Color unfavorable;
  final Color unknown;

  static const light = SignalColors(
    favorable: Color(0xFF1F7A4A),
    neutral: Color(0xFF8A5A00),
    unfavorable: Color(0xFFB3382A),
    unknown: Color(0xFF55645F),
  );

  static const dark = SignalColors(
    favorable: Color(0xFF6FCF97),
    neutral: Color(0xFFE0B050),
    unfavorable: Color(0xFFF08A7A),
    unknown: Color(0xFFA3B2AD),
  );

  @override
  SignalColors copyWith({
    Color? favorable,
    Color? neutral,
    Color? unfavorable,
    Color? unknown,
  }) => SignalColors(
    favorable: favorable ?? this.favorable,
    neutral: neutral ?? this.neutral,
    unfavorable: unfavorable ?? this.unfavorable,
    unknown: unknown ?? this.unknown,
  );

  @override
  SignalColors lerp(SignalColors? other, double t) {
    if (other == null) return this;
    return SignalColors(
      favorable: Color.lerp(favorable, other.favorable, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      unfavorable: Color.lerp(unfavorable, other.unfavorable, t)!,
      unknown: Color.lerp(unknown, other.unknown, t)!,
    );
  }
}
