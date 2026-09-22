import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../services/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_counter.dart';

class BidPhase extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  const BidPhase({super.key, required this.ctrl, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        const Text(
          'Combien de plis chaque joueur annonce-t-il ?',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 10),
        for (final p in game.players) ...[
          _BidCard(ctrl: ctrl, game: game, playerId: p.id, name: p.name),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BidCard extends StatelessWidget {
  final GameController ctrl;
  final GameState game;
  final String playerId;
  final String name;

  const _BidCard({
    required this.ctrl,
    required this.game,
    required this.playerId,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final bid = game.pendingBids[playerId] ?? 0;
    final shot = game.pendingCannonball[playerId] ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'Enchère',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 6),
            BigCounter(
              id: 'bid-$playerId',
              value: bid,
              min: 0,
              max: game.currentCards,
              showChips: true,
              onChanged: (v) => ctrl.setBid(playerId, v),
            ),
            if (game.cannonballAllowed) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _shot(
                      label: 'Chevrotine',
                      selected: !shot,
                      onTap: () => ctrl.setCannonball(playerId, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _shot(
                      label: 'Boulet',
                      selected: shot,
                      onTap: () => ctrl.setCannonball(playerId, true),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _shot({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppTheme.accent : AppTheme.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? AppTheme.ink : AppTheme.text,
            ),
          ),
        ),
      ),
    );
  }
}
