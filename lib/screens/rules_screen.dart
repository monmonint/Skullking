import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Règles / Aide')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          _Block(
            title: 'À quoi sert l\'app',
            body:
                'Compte-points hors ligne. Vous jouez les cartes à la table, '
                'puis vous saisissez mises, plis et bonus. Pas de simulation de pli.',
          ),
          _Block(
            title: 'Bonus — règle de la maison (défaut)',
            body:
                'Les bonus saisis (14, captures, 7/8, Davy Jones, Con, butin) '
                'sont ajoutés même si le joueur a raté sa mise.\n\n'
                'Pour le barème Halcyon, activez « Bonus seulement si enchère exacte » '
                'à la préparation. Les bonus ne comptent alors que si la mise est exacte '
                '(en Rascal chevrotine : moitié si l\'écart est de 1, zéro si l\'écart est ≥ 2). '
                'Le butin, lui, n\'est jamais réduit de moitié : en mode classique les deux '
                'alliés doivent être exacts, sinon personne ne marque les +20.',
          ),
          _Block(
            title: 'Score Skull King',
            body:
                'Mise de 1 ou plus, exacte : +20 × plis.\n'
                'Ratée : −10 × |plis − mise|.\n'
                'Mise 0 exacte : +10 × cartes de la manche.\n'
                'Mise 0 ratée : −10 × cartes de la manche.',
          ),
          _Block(
            title: 'Score Rascal et boulet de canon',
            body:
                'Chaque joueur a le même potentiel : 10 × cartes, quelle que soit la mise.\n'
                'Coup direct : 100 %. Écart de 1 (frappe à revers) : moitié, division entière. '
                'Écart de 2 ou plus : 0.\n\n'
                'Boulet de canon (option, choix par joueur après la mise) : '
                '15 × cartes si la mise est exacte, sinon 0. '
                'Chevrotine = Rascal habituel.\n\n'
                'Pari de Rascal le Flambeur (pouvoir, 0 / 10 / 20) : '
                'ce n\'est pas un bonus de capture. Exact → +pari, raté → −pari, '
                'même quand les autres bonus s\'appliquent aux mises ratées. '
                'Officiellement il faut encore être exact, y compris au boulet et en Rascal.',
          ),
          _Block(
            title: 'Points bonus',
            body:
                '14 couleur (jaune, vert, violet) : +10.\n'
                '14 noir : +20.\n'
                'Sirène capturée par un pirate : +20.\n'
                'Pirate capturé par Skull King : +30.\n'
                'Skull King capturé par une sirène : +40 (livret 2022).\n'
                'Alliance Butin réussie : +20 pour chacun des deux.\n'
                '8 d\'extension : +5. 7 d\'extension : −5.\n'
                'Monstre marin pris par Davy Jones : +20.\n'
                'Con pris par Skull King ou une sirène : +30.\n\n'
                'Tigresse et Scary Mary ne comptent comme pirates que si elles sont '
                'jouées en pirate. En fuite, pas de bonus de capture. '
                'Si pirate + Skull King + sirène sont dans le même pli, la sirène gagne '
                'et Skull King ne marque pas le bonus pirate.',
          ),
          _Block(
            title: 'Monstres marins',
            body:
                'Kraken : le pli est détruit, personne ne le gagne.\n'
                'Baleine blanche : le plus haut numéro gagne, couleurs ignorées. '
                'Les cartes spéciales sont détruites. S\'il n\'y a que des spéciaux, '
                'le pli est défaussé.\n'
                'Raie tachetée : comme la baleine, mais le plus petit numéro gagne.\n'
                'Si deux monstres sont dans le même pli, la deuxième carte prime '
                '(la première compte comme une fuite).\n'
                'Davy Jones retire les monstres du pli : le pli peut quand même être gagné. '
                'Saisissez +20 par monstre qu\'il capture.\n\n'
                'Comptez ces plis sans vainqueur dans « plis annulés ». '
                'La somme des plis des joueurs + annulés (+ Barbe Grise) doit égaler '
                'le nombre de cartes.',
          ),
          _Block(
            title: 'Pirates et pouvoirs',
            body:
                'Harry le Géant : après les plis, ±1 sur la mise (ou 0), une fois, '
                'borné entre 0 et le nombre de cartes. C\'est le seul pouvoir utilisable '
                'après le dernier pli.\n'
                'Rascal le Flambeur : pari 0/10/20 saisi en phase Bonus.\n'
                'Rosie : choisir qui entame le pli suivant (rappel, pas de points).\n'
                'Will le Bandit : piocher 2, défausser 2 (rappel).\n'
                'Juanita Jade : regarder les cartes non distribuées (rappel).\n'
                'Butin : jusqu\'à 2 alliances. Si vous menez avec un butin et que '
                'tout le monde fuit, pas d\'alliance.',
          ),
          _Block(
            title: 'Modes de cartes',
            body:
                'Standard 1→10 · Pas d\'impair 2,2,4,4,6,6,8,8,10,10 · '
                'Attaque éclair 5×5 · Tir de barrage 10×10 · '
                'Tourbillon 9,9,7,7,5,5,3,3,1,1 · Heure du dodo 1 carte · '
                'Prêt au combat 6→10 · Personnalisé.\n\n'
                'À 7–8 joueurs le livret demande parfois de ne pas monter jusqu\'à 10 '
                'cartes : utilisez le mode personnalisé.\n\n'
                'Barbe Grise (2 joueurs, 3 paquets) : il ne mise pas et ne marque pas. '
                'Comptez ses plis à part. Quand il joue Tigresse, c\'est une fuite.',
          ),
          _Block(
            title: 'Hors score',
            body:
                'Le 15 joker et les 0/14 d\'extension ne donnent pas de bonus à la capture. '
                'Les cartes vierges sont libres. Cette aide résume le comptage, '
                'elle ne remplace pas le livret.',
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final String body;
  const _Block({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(body, style: const TextStyle(height: 1.35, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
