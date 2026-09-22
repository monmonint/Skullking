import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pastille d'identité originale (initiale + teinte), sans portrait tiers.
class PlayerFace extends StatelessWidget {
  final String name;
  final int index;
  final double size;

  const PlayerFace({
    super.key,
    required this.name,
    required this.index,
    this.size = 40,
  });

  static const colors = <Color>[
    Color(0xFF2AD4C8),
    Color(0xFF7AD7F0),
    Color(0xFFE4B15A),
    Color(0xFF3DDC97),
    Color(0xFF8AB4F8),
    Color(0xFFFF8A80),
    Color(0xFFCE93D8),
    Color(0xFFFFCC80),
  ];

  @override
  Widget build(BuildContext context) {
    final color = colors[index % colors.length];
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color, width: 1.6),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class ScorePill extends StatelessWidget {
  final int value;
  const ScorePill(this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    final color = positive ? AppTheme.success : AppTheme.danger;
    final sign = positive ? '+' : '';
    return Text(
      '$sign$value',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
    );
  }
}
