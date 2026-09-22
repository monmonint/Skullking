# Skull King Scorekeeper (FR)

Compte-points Flutter **non officiel** pour Skull King (Halcyon / Grandpa Beck’s 2022, score Rascal, boulet de canon, extensions en saisie). Interface originale — pas d’affiliation avec ScoreNow, Grand Prix Games ou Grandpa Beck’s Games.

Identifiant Android : `fr.remi.skullkingscore`.

## Règle de score (important)

Par défaut, les **bonus sont accordés même si la mise est ratée** (14, captures, 7/8, Davy Jones, Con, et butin saisi).

Le réglage **« Bonus seulement si enchère exacte »** (désactivé par défaut) retrouve le barème classique :

- Skull King / boulet : bonus seulement si la mise est exacte
- Rascal chevrotine : bonus complets si exact, moitié (division entière) si l’écart est de 1, zéro sinon
- Butin : jamais réduit de moitié ; en mode classique les **deux** alliés doivent être exacts

Le **pari de Rascal le Flambeur** (0 / 10 / 20) reste un pari : +s’il est exact, −sinon. Ce n’est pas un bonus de capture.

## Fonctions

- Modes jouables : Standard, Pas d’impair, Attaque éclair, Tir de barrage, Tourbillon, Heure du dodo, Prêt au combat, Personnalisé
- Scores Skull King et Rascal, option boulet de canon (chevrotine / boulet par joueur)
- Kraken, Baleine blanche, Raie tachetée (plis annulés), Barbe Grise (plis à part)
- Harry le Géant **après** les plis (±1)
- Butin : jusqu’à 2 alliances
- Tigresse / Scary Mary (rappel pirate vs fuite)
- 7 (−5), 8 (+5), Davy Jones (+20 / monstre), Con capturé (+30)
- Rappels Rosie, Will le Bandit, Juanita Jade (effet de table, pas de points)
- UI française, hors ligne, historique, revanche, classement en direct
- Menus : accueil (Nouvelle partie, Historique, Règles), préparation en 3 étapes, phases Enchères → Plis → Harry → Bonus → Scores

## Hors scope

Pas de simulation carte par carte. Le 15 joker et les 0/14 d’extension ne donnent pas de points de capture (comme le livret). Les pouvoirs de table ne changent pas le score : l’app les rappelle seulement.

## Ambiguïtés

- Kraken + Baleine (ou Raie) dans le même pli : la **deuxième** carte prime ; la première compte comme une fuite.
- Sirène + pirate + Skull King : la sirène gagne, pas de bonus « pirate capturé ».
- Tigresse / Scary Mary en fuite : pas un pirate pour les bonus.
- Skull King pris par une sirène : **+40** (livret FR 2022).
- Moitié Rascal : division entière du total des bonus de cartes/captures (`~/`).

## Tests

```bash
flutter test
```

Le test `bonus awarded on missed bid when classicBonusGate is false` verrouille la règle maison.

## Build Android

Les APK ne sont pas versionnés (`artifacts/` est ignoré). Script :

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$JAVA_HOME/bin:$HOME/flutter/bin:$PATH"
flutter test
./tool/build_apks.sh
```

Produits :

| Fichier | Contenu |
|---------|---------|
| `artifacts/skull-king-scorekeeper-arm64-release.apk` | arm64-v8a seul (téléphones récents, cible &lt; 25 Mo) |
| `artifacts/skull-king-scorekeeper.apk` | même binaire arm64, nom court |
| `artifacts/skull-king-scorekeeper-fat-release.apk` | multi-ABI (armeabi-v7a, arm64-v8a, x86_64) |

Si cette machine n’a pas le SDK Flutter / Android, les tests et le code restent la source de vérité ; lancez les commandes ci-dessus sur un poste où `flutter doctor` est vert. Voir `INSTALL_FR.md`.
