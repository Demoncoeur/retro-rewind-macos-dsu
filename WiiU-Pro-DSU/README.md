# Wii U Pro DSU — app macOS

Cette version modifiée de WiiU Pro connecte une ou plusieurs manettes Wii U Pro au Mac, lit leurs entrées via Bluetooth et les publie sur le serveur DSU local (`127.0.0.1:26760`). Le client DSU ajouté au runtime Retro Rewind peut ensuite les exposer au jeu comme manettes SDL pour effectuer les bindings dans Retro Rewind.

Le code source de l’application et du serveur DSU est dans `Sources/`. Cette copie conserve les modifications locales utilisées avec l’app WiiU Pro fonctionnelle. Le dépôt d’origine de l’application est [zospy/wiiu-pro-mac](https://github.com/zospy/wiiu-pro-mac).

## Compilation

Sur macOS, avec les outils en ligne de commande Xcode installés :

```sh
cd WiiU-Pro-DSU
./build.sh
open "build/WiiU Pro.app"
```

Le script produit l’application dans `build/WiiU Pro.app` et l’outil facultatif `build/wiiu-pro-dsu`. L’application enregistre un journal par lancement dans `logs/`. Elle nécessite l’autorisation Bluetooth et, pour le mode clavier/souris, l’autorisation Accessibilité dans Réglages Système.

Gardez WiiU Pro ouverte pendant Retro Rewind. Le client du jeu doit écouter le serveur DSU sur `127.0.0.1:26760`. Les journaux peuvent contenir des adresses Bluetooth : ne les publiez pas.

## État

La connexion et les boutons ont été vérifiés avec l’app WiiU Pro sur le Mac de développement. La prise en charge simultanée de quatre manettes doit être vérifiée par les personnes qui la compilent sur leur matériel.
