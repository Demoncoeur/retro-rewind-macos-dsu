# Wii U Pro sur macOS avec Retro Rewind

Ce dépôt contient les deux éléments utilisés ensemble :

- [`WiiU-Pro-DSU/`](WiiU-Pro-DSU/) : sources de l’app macOS modifiée qui connecte les manettes Wii U Pro et publie leurs entrées sur DSU.
- [`patch-and-build.sh`](patch-and-build.sh) : script qui modifie et recompile le runtime Retro Rewind/WiiCompiled pour qu’il lise le serveur DSU comme quatre manettes SDL.

La version de WiiU Pro qui avait été indiquée au départ est le dépôt d’origine [zospy/wiiu-pro-mac](https://github.com/zospy/wiiu-pro-mac). Le dossier `WiiU-Pro-DSU/` contient les sources modifiées utilisées avec Retro Rewind; ce n’est donc pas seulement un lien vers l’application d’origine.

## Utilisation

1. Compilez l’app depuis [`WiiU-Pro-DSU/README.md`](WiiU-Pro-DSU/README.md) et gardez-la ouverte.
2. Utilisez `patch-and-build.sh` selon les instructions de ce script pour préparer le runtime Retro Rewind.
3. Dans Retro Rewind, attribuez les boutons des manettes DSU dans les réglages habituels.

Les applications compilées, les fichiers du jeu et les journaux locaux ne sont pas inclus dans ce dépôt.
