# Installation — Skull King Score (non officiel)

Compte-points hors ligne pour Skull King.
Aucune affiliation avec ScoreNow, Grand Prix Games ou Grandpa Beck’s Games.

## Installer l’APK (Android)

1. Copiez un APK du dossier `artifacts/` (ou une pièce jointe de release) sur le téléphone.
2. Ouvrez le fichier → autorisez **Sources inconnues** si demandé.
3. Installez et lancez **Skull King Score**.

| Fichier | Pour qui |
|---------|----------|
| `skull-king-scorekeeper-arm64-release.apk` (ou `skull-king-scorekeeper.apk`) | Téléphones 64 bits récents. Environ 18 Mo. |
| `skull-king-scorekeeper-fat-release.apk` | 32 bits ARM, 64 bits et x86_64. Environ 50 Mo. |

Non destiné au Play Store. Identifiant : `fr.remi.skullkingscore`.

Depuis l’accueil : **Menu → Rechercher une mise à jour**. Si une version plus récente est publiée, **Mettre à jour** télécharge l’APK (arm64 sur un téléphone 64 bits, sinon le multi-ABI) et ouvre l’installateur Android. Autorisez l’installation depuis cette application si le système le demande.

Si les APK ne sont pas dans le dépôt (dossier `artifacts/` ignoré par git), construisez-les avec `./tool/build_apks.sh` — voir le README.

## Préparer une partie

1. **Nouvelle partie**
2. **Joueurs** (2 à 8) → Continuer
3. **Mode** de cartes → Continuer
4. **Options** : comptage, bonus, extensions → **Lancer la partie**

Raccourcis : « Journal 2022 » (Kraken, Baleine, Butin, Harry, Rascal, rappels) et « Extension score » (Raie, 7/8, Davy Jones, Con).

## Pendant la manche

Bandeau de classement, puis les étapes :

**Enchères → Plis → Harry (si activé) → Bonus → Scores**

On peut revenir aux étapes précédentes tant que la manche n’est pas calculée. Boutons ronds − / + pour les mises, les plis et les bonus. Les pastilles en haut de l’écran Bonus choisissent le joueur. L’onglet Stats reprend les parties archivées.

Après validation, touchez une manche (écran Scores, icône historique, ou résumé final) pour corriger enchères, plis et bonus. Les totaux sont recalculés.

Une nouvelle partie reprend les joueurs, le mode et les cartes spéciales de la précédente. Tout reste modifiable avant de lancer.

## Score

### Skull King (classique)
- Exact (mise ≥ 1) : +20 × plis
- Raté : −10 × écart
- Mise 0 : +10 × cartes si exact, −10 × cartes sinon

### Rascal
- Potentiel : 10 × cartes, quelle que soit la mise
- Coup direct : tout ; écart de 1 : moitié (division entière) ; écart ≥ 2 : 0
- **Boulet de canon** : 15 × cartes si exact, sinon 0 (choix Chevrotine / Boulet)

### Bonus
- 14 couleur +10, 14 noir +20
- Sirène par pirate +20, pirate par Skull King +30, Skull King par sirène +40
- Butin +20 chacun (2 alliances max)
- 8 +5, 7 −5, Davy Jones +20 par monstre, Con capturé +30

**Par défaut, ces bonus comptent même si la mise est ratée.**  
Activez « Bonus seulement si enchère exacte » pour le barème Halcyon (en Rascal chevrotine, moitié des bonus de cartes si l’écart est de 1 ; le butin exige toujours que les deux soient exacts).

Le pari Rascal (0/10/20) est à part : gagné seulement si la mise est exacte, perdu sinon.

### Monstres et Barbe Grise
- Kraken : pli détruit
- Baleine : plus haut numéro ; Raie : plus petit numéro ; que des spéciaux → annulé
- Deux monstres : la 2ᵉ carte prime
- La somme plis + annulés + Barbe Grise doit égaler le nombre de cartes
- Tigresse / Scary Mary = pirate seulement si jouées en pirate
- Harry : ±1 après les plis

## Modes

| Mode | Séquence |
|------|----------|
| Standard | 1→10 |
| Pas d’impair | 2,2,4,4,6,6,8,8,10,10 |
| Attaque éclair | 5×5 |
| Tir de barrage | 10×10 |
| Tourbillon | 9,9,7,7,5,5,3,3,1,1 |
| Heure du dodo | 1 |
| Prêt au combat | 6→10 |
| Personnalisé | liste libre |

## Désinstaller

Paramètres → Applications → Skull King Score → Désinstaller.
