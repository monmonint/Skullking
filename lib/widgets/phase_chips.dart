import 'package:flutter/material.dart';
import '../services/game_controller.dart';
import '../theme/app_theme.dart';

class PhaseChips extends StatelessWidget {
  final List<RoundPhase> phases;
  final RoundPhase current;
  final ValueChanged<RoundPhase>? onTap;

  const PhaseChips({
    super.key,
    required this.phases,
    required this.current,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = phases.indexOf(current);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: phases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final phase = phases[i];
          final selected = phase == current;
          final done = currentIndex > i;
          final canTap = onTap != null && done;
          final bg = selected
              ? AppTheme.accent
              : done
                  ? AppTheme.surface2
                  : AppTheme.bg;
          final fg = selected ? AppTheme.ink : done ? AppTheme.text : AppTheme.muted;
          return Material(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: canTap ? () => onTap!(phase) : null,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppTheme.accent : AppTheme.cardBorder,
                  ),
                ),
                child: Text(
                  phaseLabelFr(phase),
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
