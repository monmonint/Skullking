import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../scoring/scoring_engine.dart';
import '../../services/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_counter.dart';

class BonusPhase extends StatefulWidget {
  final GameController ctrl;
  final GameState game;
  const BonusPhase({super.key, required this.ctrl, required this.game});

  @override
  State<BonusPhase> createState() => _BonusPhaseState();
}

class _BonusPhaseState extends State<BonusPhase> {
  String? _allyA;
  String? _allyB;

  GameController get ctrl => widget.ctrl;
  GameState get game => widget.game;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Text(
          _header(),
          style: const TextStyle(color: AppTheme.muted, height: 1.35),
        ),
        if (game.expansions.tigressNotes) ...[
          const SizedBox(height: 8),
          const Text(
            'Tigresse / Scary Mary : comptez-les comme pirates seulement '
            'si elles ont été jouées en pirate (pas en fuite).',
            style: TextStyle(color: AppTheme.accent, fontSize: 13, height: 1.35),
          ),
        ],
        if (game.expansions.rascalWager) ...[
          const SizedBox(height: 14),
          const Text('Pari Rascal',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            '0 / 10 / 20. Gagné seulement si la mise est exacte, perdu sinon.',
            style: TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          for (final p in game.players) ...[
            _wagerCard(p),
            const SizedBox(height: 8),
          ],
        ],
        if (game.expansions.loot) ...[
          const SizedBox(height: 8),
          _lootCard(),
        ],
        if (_showCaptures) ...[
          const SizedBox(height: 8),
          const Text('Bonus de cartes et captures',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (_eligiblePlayers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Personne n\'est éligible : en mode classique, les bonus '
                'de capture demandent une enchère exacte'
                ' (ou un écart de 1 en Rascal chevrotine).',
                style: TextStyle(color: AppTheme.muted),
              ),
            ),
          for (final p in _eligiblePlayers) ...[
            _captureCard(p),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  String _header() {
    if (!game.classicBonusGate) {
      return 'Les bonus comptent même si la mise est ratée.';
    }
    if (game.scoring == ScoringSystem.rascal) {
      return 'Mode classique : bonus complets si exact, moitié si écart de 1 '
          '(Rascal chevrotine), aucun sinon. Le boulet exige une mise exacte.';
    }
    return 'Mode classique : bonus seulement si l\'enchère est exacte.';
  }

  bool get _showCaptures => game.bonusesEnabled;

  List<Player> get _eligiblePlayers {
    if (!game.bonusesEnabled) return const [];
    return game.players.where(_eligible).toList();
  }

  bool _eligible(Player p) {
    if (!game.classicBonusGate) return true;
    final diff =
        (game.effectiveBid(p.id) - (game.pendingTricks[p.id] ?? 0)).abs();
    final cannon =
        game.cannonballAllowed && (game.pendingCannonball[p.id] ?? false);
    if (game.scoring == ScoringSystem.skullKing || cannon) return diff == 0;
    return diff <= 1;
  }

  Widget _wagerCard(Player p) {
    final w = game.pendingRascalWagers[p.id] ?? 0;
    final exact = game.isExactPending(p.id);
    final preview = w == 0 ? 0 : (exact ? w : -w);
    final sign = preview > 0 ? '+' : '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(
              w == 0 ? 'Pas de pari' : 'Effet $sign$preview',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final value in const [0, 10, 20]) ...[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: value == 20 ? 0 : 8),
                      child: _choice(
                        label: '$value',
                        selected: w == value,
                        onTap: () => ctrl.setRascalWager(p.id, value),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _lootCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alliances Butin',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              game.classicBonusGate
                  ? 'Deux cartes maximum. +20 chacun seulement si les deux sont exacts.'
                  : 'Deux cartes maximum. +20 chacun, même si une mise est ratée.',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < game.pendingLootAlliances.length; i++)
              _allianceTile(i, game.pendingLootAlliances[i]),
            if (game.pendingLootAlliances.length < 2) ...[
              const SizedBox(height: 6),
              const Text('Qui pose le butin ?',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted)),
              const SizedBox(height: 6),
              _playerWrap(selected: _allyA, onPick: (id) => setState(() => _allyA = id)),
              const SizedBox(height: 8),
              const Text('Qui le capture ?',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted)),
              const SizedBox(height: 6),
              _playerWrap(selected: _allyB, onPick: (id) => setState(() => _allyB = id)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _allyA != null && _allyB != null && _allyA != _allyB
                    ? () {
                        ctrl.addLootAlliance(_allyA!, _allyB!);
                        setState(() {
                          _allyA = null;
                          _allyB = null;
                        });
                      }
                    : null,
                child: const Text('Ajouter l\'alliance'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _allianceTile(int index, LootAlliance a) {
    final scores = ScoringEngine.lootAllianceScores(
      exactA: game.isExactPending(a.playerA),
      exactB: game.isExactPending(a.playerB),
      classicBonusGate: game.classicBonusGate,
    );
    final names =
        '${game.nameOf(a.playerA) ?? '?'} + ${game.nameOf(a.playerB) ?? '?'}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(names),
      subtitle: Text(
        scores ? '+20 chacun' : 'Ignorée : les deux doivent être exacts',
        style: TextStyle(color: scores ? AppTheme.success : AppTheme.danger),
      ),
      trailing: IconButton(
        onPressed: () => ctrl.removeLootAlliance(index),
        icon: const Icon(Icons.close),
      ),
    );
  }

  Widget _playerWrap({
    required String? selected,
    required ValueChanged<String> onPick,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final p in game.players)
          ChoiceChip(
            label: Text(p.name),
            selected: selected == p.id,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected == p.id ? AppTheme.ink : AppTheme.text,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) => onPick(p.id),
          ),
      ],
    );
  }

  Widget _captureCard(Player p) {
    final b = game.pendingBonuses[p.id] ?? const RoundBonuses();
    final diff =
        (game.effectiveBid(p.id) - (game.pendingTricks[p.id] ?? 0)).abs();
    final cannon =
        game.cannonballAllowed && (game.pendingCannonball[p.id] ?? false);
    final half = game.classicBonusGate &&
        game.scoring == ScoringSystem.rascal &&
        !cannon &&
        diff == 1;
    final note = half
        ? 'Frappe à revers : ces bonus seront divisés par 2.'
        : game.isExactPending(p.id)
            ? 'Mise exacte'
            : 'Mise ratée — bonus quand même';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(note, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            const SizedBox(height: 6),
            _row('14 couleur (+10)', b.colorFourteens, 'bonus-${p.id}-color', (v) {
              ctrl.setBonuses(p.id, b.copyWith(colorFourteens: v));
            }),
            _row('14 noir (+20)', b.blackFourteens, 'bonus-${p.id}-black', (v) {
              ctrl.setBonuses(p.id, b.copyWith(blackFourteens: v));
            }),
            _row('Sirène par pirate (+20)', b.mermaidByPirate, 'bonus-${p.id}-mermaid',
                (v) {
              ctrl.setBonuses(p.id, b.copyWith(mermaidByPirate: v));
            }),
            _row('Pirate par Skull King (+30)', b.pirateBySkullKing,
                'bonus-${p.id}-pirate', (v) {
              ctrl.setBonuses(p.id, b.copyWith(pirateBySkullKing: v));
            }),
            _row('Skull King par sirène (+40)', b.skullKingByMermaid,
                'bonus-${p.id}-sk', (v) {
              ctrl.setBonuses(p.id, b.copyWith(skullKingByMermaid: v));
            }),
            if (game.expansions.bonusSevensEights) ...[
              _row('8 d\'extension (+5)', b.eights, 'bonus-${p.id}-eight', (v) {
                ctrl.setBonuses(p.id, b.copyWith(eights: v));
              }),
              _row('7 d\'extension (−5)', b.sevens, 'bonus-${p.id}-seven', (v) {
                ctrl.setBonuses(p.id, b.copyWith(sevens: v));
              }),
            ],
            if (game.expansions.davyJones)
              _row('Davy Jones (+20 / monstre)', b.davyJonesSeaMonsters,
                  'bonus-${p.id}-davy', (v) {
                ctrl.setBonuses(p.id, b.copyWith(davyJonesSeaMonsters: v));
              }),
            if (game.expansions.con)
              _row('Con capturé (+30)', b.conCaptured, 'bonus-${p.id}-con', (v) {
                ctrl.setBonuses(p.id, b.copyWith(conCaptured: v));
              }),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, int value, String id, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          BigCounter(
            id: id,
            value: value,
            min: 0,
            max: 10,
            compact: true,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _choice({
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
