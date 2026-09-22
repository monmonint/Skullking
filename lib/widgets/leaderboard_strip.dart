import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';

class LeaderboardStrip extends StatelessWidget {
  final GameState game;
  const LeaderboardStrip({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final ranked = game.rankedPlayers();
    if (ranked.isEmpty) return const SizedBox.shrink();
    final leader = ranked.first.id;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ranked.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = ranked[i];
          final top = p.id == leader && game.completedRounds.isNotEmpty;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: top ? AppTheme.accent.withValues(alpha: 0.16) : AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: top ? AppTheme.accent : AppTheme.cardBorder,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}. ${p.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: top ? AppTheme.accent : AppTheme.text,
                  ),
                ),
                Text(
                  '${game.totalFor(p.id)} pts',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
