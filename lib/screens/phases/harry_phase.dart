import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../services/game_controller.dart';
import '../../theme/app_theme.dart';

class HarryPhase extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  const HarryPhase({super.key, required this.ctrl, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        const Text(
          'Harry le Géant — si un joueur a gagné un pli avec Harry, '
          'ajustez sa mise de −1, 0 ou +1. Le pouvoir s\'utilise après les plis.',
          style: TextStyle(color: AppTheme.muted, height: 1.35),
        ),
        const SizedBox(height: 12),
        for (final p in game.players) ...[
          _HarryCard(ctrl: ctrl, game: game, player: p),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _HarryCard extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  final Player player;
  const _HarryCard({
    required this.ctrl,
    required this.game,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final base = game.pendingBids[player.id] ?? 0;
    final d = game.pendingHarryDeltas[player.id] ?? 0;
    final tricks = game.pendingTricks[player.id] ?? 0;
    final eff = game.effectiveBid(player.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(player.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'Mise $base · plis $tricks → effective $eff',
              style: const TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final value in const [-1, 0, 1]) ...[
                  Expanded(child: _delta(value, d == value)),
                  if (value != 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _delta(int value, bool selected) {
    final label = value > 0 ? '+$value' : '$value';
    return Material(
      color: selected ? AppTheme.accent : AppTheme.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ctrl.setHarryDelta(player.id, value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: selected ? AppTheme.ink : AppTheme.text,
            ),
          ),
        ),
      ),
    );
  }
}
