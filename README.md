# Skull King Scorekeeper (FR)

Unofficial Flutter scorekeeper for Skull King (Halcyon / Grandpa Beck’s 2022 classic scoring). Original UI — not affiliated with ScoreNow.

## Features
- Modes: Standard, Pas d’impair, Attaque éclair, Tir de barrage, Tourbillon, Heure du dodo, Prêt au combat, Custom
- Classic scoring + capture bonuses
- Expansions: Kraken, White Whale, Harry the Giant, Loot, Rascal wager; Tigress/Scary Mary notes
- French UI, offline, history, rematch, player exact-bid stats

## Not implemented
- **Full Rascal / Cannonball scoring system** (alternate point method with direct hit / near miss / miss and optional cannonball 15×cards). Only Rascal *pirate ability* wager (0/10/20) is supported.
- Table effects for Rosie D’Laney, Bahij/Will the Bandit, Juanita Jade (no score impact).
- Live trick simulation (users enter results).

## Ambiguities handled
- Kraken+Whale same trick → second card wins (official FAQ); first acts as Escape.
- Mermaid+Pirate+SK → Mermaid wins; SK does not get pirate-capture bonus.
- Tigress as Escape → not a pirate for capture bonuses.
- SK←Mermaid bonus = **+40** (2022 FR rulebook), not older +50 editions.

## Build
```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export ANDROID_HOME=/home/box/sdk/android-sdk
export PATH=$JAVA_HOME/bin:/home/box/sdk/flutter-sdk/bin:$PATH
flutter test
flutter build apk --release --target-platform android-arm64
cp build/app/outputs/flutter-apk/app-release.apk artifacts/skull-king-scorekeeper.apk
cp build/app/outputs/flutter-apk/app-release.apk artifacts/skull-king-scorekeeper-arm64-release.apk
```

See `INSTALL_FR.md` for install steps.
