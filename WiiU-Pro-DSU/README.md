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

La dernière release GitHub fournit aussi `WiiU Pro.app` dans une archive ZIP pour Apple Silicon. Cette app est signée localement, sans notarisation Apple; au premier lancement, macOS peut demander de confirmer l’ouverture avec clic droit → **Ouvrir**.

Le script produit l’application dans `build/WiiU Pro.app` et l’outil facultatif `build/wiiu-pro-dsu`. Il ajoute à l’app l’icône Wii U Pro et le script `patch-and-build.sh`. Les journaux restent dans `logs/` du projet. L’application enregistre un journal par lancement dans `logs/`. Elle nécessite l’autorisation Bluetooth et, pour le mode clavier/souris, l’autorisation Accessibilité dans Réglages Système.

Dans l’app, **Modifier et compiler Retro Rewind** lance le patch intégré sur le BuildWorkspace local de WiiCompiled. Le script sauvegarde ses fichiers avant modification et compile une nouvelle app Retro Rewind sur le Bureau; la sortie s’affiche dans le journal de WiiU Pro.

À la connexion, les voyants indiquent les ports DSU : voyant 1 pour le joueur 1, jusqu’au voyant 4 pour le joueur 4. Pour fabriquer un build partageable dont les journaux n’embarquent pas le chemin local du projet, compilez avec `WIIUPRO_PORTABLE_BUILD=1 ./build.sh`; ces journaux seront créés dans `~/Library/Application Support/WiiU Pro/logs/`.

Gardez WiiU Pro ouverte pendant Retro Rewind. Le client du jeu doit écouter le serveur DSU sur `127.0.0.1:26760`. Les journaux peuvent contenir des adresses Bluetooth : ne les publiez pas.

## État

La connexion et les boutons ont été vérifiés avec l’app WiiU Pro sur le Mac de développement. La prise en charge simultanée de quatre manettes doit être vérifiée par les personnes qui la compilent sur leur matériel.
