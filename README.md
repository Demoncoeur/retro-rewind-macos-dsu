# Wii U Pro macOS avec Retro Rewind

Ce dépôt réunit les deux éléments utilisés ensemble :

- [`WiiU-Pro-DSU/`](WiiU-Pro-DSU/) : sources de l’app macOS modifiée qui connecte les manettes Wii U Pro et publie leurs entrées sur DSU.
- [`patch-and-build.sh`](patch-and-build.sh) : script qui modifie et recompile le runtime Retro Rewind/WiiCompiled pour qu’il lise les manettes DSU comme quatre manettes SDL.

Le dépôt d’origine de l’application est [zospy/wiiu-pro-mac](https://github.com/zospy/wiiu-pro-mac). Le dossier `WiiU-Pro-DSU/` contient les sources modifiées utilisées avec Retro Rewind.

## Compiler l’app Wii U Pro DSU

Sur macOS, avec les outils en ligne de commande Xcode installés :

```sh
cd WiiU-Pro-DSU
./build.sh
open "build/WiiU Pro.app"
```

L’application résultante se trouve dans `WiiU-Pro-DSU/build/WiiU Pro.app`. Gardez-la ouverte pendant le jeu. Les instructions détaillées et la configuration des journaux sont dans [`WiiU-Pro-DSU/README.md`](WiiU-Pro-DSU/README.md).

## Préparer Retro Rewind

Cette modification règle deux problèmes rencontrés avec l’entrée Wii U Pro DSU :

1. Le client DSU initialise les sous-systèmes SDL joystick et gamepad lorsque le runtime ne l’a pas déjà fait.
2. Le pilote Wii intégré à SDL est désactivé pour qu’il ne prenne pas la connexion Bluetooth utilisée par WiiU Pro. L’hôte Wii Remote dédié de WiiCompiled reste disponible.

### Prérequis

- macOS avec WiiCompiled Setup et son `BuildWorkspace` local installé.
- Un dossier de compilation macOS configuré dans `BuildWorkspace/native-build-macos-<architecture>`.
- `cmake`, Python 3, `codesign` et le script `Launcher/macos/publish-app.command` de WiiCompiled. L’outil trouve CMake dans les outils inclus avec WiiCompiled Setup ou dans `PATH`.
- L’app WiiU Pro ouverte et son serveur DSU accessible sur `127.0.0.1:26760` au lancement du jeu.

### Exécuter le patch et compiler

Téléchargez ce dépôt, ouvrez Terminal dans son dossier, puis lancez :

```bash
bash ./patch-and-build.sh
```

Le script utilise `~/Library/Application Support/WiiCompiled/BuildWorkspace` par défaut. Il sauvegarde les deux fichiers source avant modification dans `~/Library/Application Support/WiiU Pro RetroRewind/backups/`.

Il recompile la cible `RetroRewind` et crée sur le Bureau un nouveau dossier contenant `RetroRewind.app`. Il s’arrête si le chemin de sortie existe déjà.

Pour choisir un autre dossier de travail ou de sortie :

```bash
bash ./patch-and-build.sh --workspace "/path/to/BuildWorkspace" --output-dir "$HOME/Desktop/RetroRewind-DSU"
```

Pour appliquer seulement les changements source, sans compiler :

```bash
bash ./patch-and-build.sh --patch-only
```

Le script peut être relancé : les fichiers déjà modifiés ne sont pas patchés une seconde fois.

## Vérifier les manettes

Gardez WiiU Pro ouverte et connectée, puis lancez la version générée de Retro Rewind. Les logs doivent indiquer l’activation de SDL joystick/gamepad et la création des manettes DSU. Appuyez sur un bouton pour confirmer la réception d’un premier rapport, puis attribuez `Wii U Pro Controller (DSU 1)` dans les bindings de Retro Rewind.

Les applications compilées, les fichiers du jeu et les journaux locaux ne sont pas inclus dans ce dépôt.
