import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../scoring/scoring_engine.dart';
import '../services/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/leaderboard_strip.dart';
import '../widgets/phase_chips.dart';
import 'phases/bid_phase.dart';
import 'phases/bonus_phase.dart';
import 'phases/harry_phase.dart';
import 'phases/review_phase.dart';
import 'phases/tricks_phase.dart';
import 'summary_screen.dart';

class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GameController>();
    final g = ctrl.game;
    if (g == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partie')),
        body: const Center(child: Text('Aucune partie active')),
      );
    }

    final cards = g.isFinished ? 0 : g.currentCards;
    final title = g.isFinished
        ? 'Fin de partie'
        : 'Manche ${g.currentRoundIndex + 1}/${g.roundSequence.length}';
    final subtitle = g.isFinished
        ? g.mode.labelFr
        : '$cards carte${cards > 1 ? 's' : ''} · ${g.mode.labelFr}';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          LeaderboardStrip(game: g),
          const SizedBox(height: 8),
          PhaseChips(
            phases: visiblePhases(g),
            current: ctrl.phase,
            onTap: ctrl.phase == RoundPhase.review ? null : ctrl.goToPhase,
          ),
          const SizedBox(height: 8),
          Expanded(child: _phase(ctrl, g)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (_canBack(ctrl)) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: ctrl.goBack,
                    child: const Text('Retour'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  key: const Key('play-next'),
                  onPressed: () => _onPrimary(context, ctrl, g),
                  child: Text(_primaryLabel(ctrl, g)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canBack(GameController ctrl) {
    if (ctrl.game == null || ctrl.phase == RoundPhase.review) return false;
    return visiblePhases(ctrl.game!).indexOf(ctrl.phase) > 0;
  }

  String _primaryLabel(GameController ctrl, GameState g) {
    switch (ctrl.phase) {
      case RoundPhase.bidding:
        return 'Valider les enchères';
      case RoundPhase.tricks:
        if (g.expansions.harryTheGiant) return 'Harry le Géant';
        if (g.hasBonusStep) return 'Bonus';
        return 'Calculer les scores';
      case RoundPhase.harry:
        return g.hasBonusStep ? 'Bonus' : 'Calculer les scores';
      case RoundPhase.bonuses:
        return 'Calculer les scores';
      case RoundPhase.review:
        return g.isFinished ? 'Résumé final' : 'Manche suivante';
    }
  }

  void _onPrimary(BuildContext context, GameController ctrl, GameState g) {
    switch (ctrl.phase) {
      case RoundPhase.bidding:
        ctrl.confirmBids();
      case RoundPhase.tricks:
        ctrl.confirmTricks();
      case RoundPhase.harry:
        ctrl.confirmHarry();
      case RoundPhase.bonuses:
        ctrl.confirmBonuses();
      case RoundPhase.review:
        if (g.isFinished) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SummaryScreen()),
          );
        } else {
          ctrl.nextRoundOrFinish();
        }
    }
  }

  Widget _phase(GameController ctrl, GameState g) {
    switch (ctrl.phase) {
      case RoundPhase.bidding:
        return BidPhase(ctrl: ctrl, game: g);
      case RoundPhase.tricks:
        return TricksPhase(ctrl: ctrl, game: g);
      case RoundPhase.harry:
        return HarryPhase(ctrl: ctrl, game: g);
      case RoundPhase.bonuses:
        return BonusPhase(ctrl: ctrl, game: g);
      case RoundPhase.review:
        return ReviewPhase(game: g);
    }
  }
}
