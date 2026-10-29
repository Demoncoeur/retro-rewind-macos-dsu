# Retro Rewind macOS DSU patch

This helper applies the Wii U Pro DSU input fix to a local WiiCompiled build workspace and produces a patched `RetroRewind.app` for macOS.

It fixes two issues seen with the Wii U Pro DSU client:

1. The DSU client now initializes SDL's joystick and gamepad subsystems when the runtime has not initialized them.
2. SDL's built-in Wii HIDAPI driver is disabled so it does not claim the Bluetooth controller used by Wii U Pro. WiiCompiled's dedicated Wii Remote host remains available when enabled.

This repository contains only the patching/build script and documentation. It does not include WiiCompiled, Retro Rewind game files, or proprietary source code.

## Requirements

- macOS with the WiiCompiled Setup app and its local `BuildWorkspace` installed.
- A configured macOS build directory under `BuildWorkspace/native-build-macos-<architecture>`.
- `cmake`, Python 3, `codesign`, and the WiiCompiled `Launcher/macos/publish-app.command` script. The helper finds CMake in WiiCompiled Setup's bundled tools or on `PATH`.
- A Wii U Pro app running its DSU server on `127.0.0.1:26760` when using the resulting game build.

## Use

Download this repository, open Terminal in its folder, then run:

```bash
./patch-and-build.sh
```

The helper uses `~/Library/Application Support/WiiCompiled/BuildWorkspace` by default. It backs up the two source files before changing them under:

```text
~/Library/Application Support/WiiU Pro RetroRewind/backups/
```

It rebuilds the `RetroRewind` target and creates a newly named folder on the Desktop containing `RetroRewind.app`. It stops instead of overwriting an existing app at the chosen output path.

To use a non-default workspace or output folder:

```bash
./patch-and-build.sh --workspace "/path/to/BuildWorkspace" --output-dir "$HOME/Desktop/RetroRewind-DSU"
```

To apply the source changes without compiling:

```bash
./patch-and-build.sh --patch-only
```

The script is safe to rerun: already patched source files are left as they are, and the build still runs unless `--patch-only` is supplied.

## Confirm the result

Keep Wii U Pro open and connected, then launch the generated app. Its runtime log should include:

```text
DSU client: SDL joystick=actif gamepad=actif
DSU client: SDL manette 1 créée
```

After a controller button is pressed, it should also log `premier rapport reçu`. Map the created `Wii U Pro Controller (DSU 1)` gamepad in Retro Rewind's controller bindings.

## Français

Le script applique le correctif DSU au BuildWorkspace local de WiiCompiled, sauvegarde les fichiers source d'origine, compile Retro Rewind et place l'application générée dans un nouveau dossier du Bureau. Il ne contient pas les fichiers propriétaires de WiiCompiled ou de Retro Rewind.

Exécuter `bash ./patch-and-build.sh` dans Terminal. Pour choisir un autre BuildWorkspace :

```bash
./patch-and-build.sh --workspace "/chemin/vers/BuildWorkspace"
```
