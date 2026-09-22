import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Gros contrôle − / valeur / + , avec pastilles optionnelles.
class BigCounter extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? id;
  final bool compact;
  final bool showChips;

  /// Rangée courte − valeur +, pour la placer à droite d'une carte joueur.
  final bool inline;

  const BigCounter({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.id,
    this.compact = false,
    this.showChips = false,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 52.0;
    final font = compact ? 18.0 : 26.0;
    final valueBox = SizedBox(
      width: inline ? (compact ? 28 : 36) : null,
      child: Text(
        '$value',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: font,
          fontWeight: FontWeight.w800,
          color: AppTheme.text,
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: inline ? MainAxisSize.min : MainAxisSize.max,
          children: [
            _step(
              icon: Icons.remove,
              enabled: value > min,
              onTap: () => onChanged(value - 1),
              key: id == null ? null : Key('$id-minus'),
              size: size,
            ),
            if (inline) valueBox else Expanded(child: valueBox),
            _step(
              icon: Icons.add,
              enabled: value < max,
              onTap: () => onChanged(value + 1),
              key: id == null ? null : Key('$id-plus'),
              size: size,
            ),
          ],
        ),
        if (showChips && max - min <= 12 && max <= 12) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (var n = min; n <= max; n++)
                _chip(n),
            ],
          ),
        ],
      ],
    );
  }

  Widget _chip(int n) {
    final selected = n == value;
    return Material(
      color: selected ? AppTheme.accent : AppTheme.surface2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onChanged(n),
        child: Container(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$n',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? AppTheme.ink : AppTheme.text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _step({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required Key? key,
    required double size,
  }) {
    return Material(
      key: key,
      color: enabled ? AppTheme.surface2 : AppTheme.bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: enabled ? AppTheme.accent : AppTheme.muted,
          ),
        ),
      ),
    );
  }
}
