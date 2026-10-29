#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./patch-and-build.sh [--workspace DIR] [--output-dir DIR] [--patch-only]

Patch WiiCompiled's local Retro Rewind runtime for Wii U Pro DSU input.
By default, patch the source, build RetroRewind, and package a new macOS app.

Options:
  --workspace DIR   WiiCompiled BuildWorkspace (default: ~/Library/Application Support/WiiCompiled/BuildWorkspace)
  --output-dir DIR  Parent directory for RetroRewind.app (default: a unique folder on the Desktop)
  --patch-only      Back up and patch source files without building or packaging
  -h, --help        Show this help
EOF
}

workspace="${HOME}/Library/Application Support/WiiCompiled/BuildWorkspace"
output_dir=""
patch_only=0

while (($#)); do
    case "$1" in
        --workspace)
            [[ $# -ge 2 ]] || { echo "Missing value for --workspace" >&2; exit 2; }
            workspace=$2
            shift 2
            ;;
        --output-dir)
            [[ $# -ge 2 ]] || { echo "Missing value for --output-dir" >&2; exit 2; }
            output_dir=$2
            shift 2
            ;;
        --patch-only)
            patch_only=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

[[ "$(uname -s)" == Darwin ]] || { echo "This helper supports macOS only." >&2; exit 1; }

dsu_file="$workspace/runtime/src/dsu_client.cpp"
wiimote_file="$workspace/runtime/src/wiimote/wiimote_host.cpp"
build_dir="$workspace/native-build-macos-$(uname -m)"
publisher="$workspace/Launcher/macos/publish-app.command"

for file in "$dsu_file" "$wiimote_file"; do
    [[ -f "$file" ]] || { echo "Required WiiCompiled source file not found: $file" >&2; exit 1; }
done

if [[ -z "$output_dir" ]]; then
    output_dir="$HOME/Desktop/RetroRewind-DSU-$(date +%Y%m%d-%H%M%S)"
fi

backup_dir="$HOME/Library/Application Support/WiiU Pro RetroRewind/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"
cp -p "$dsu_file" "$backup_dir/dsu_client.cpp"
cp -p "$wiimote_file" "$backup_dir/wiimote_host.cpp"
echo "Source backup: $backup_dir"

python3 - "$dsu_file" "$wiimote_file" <<'PY'
from pathlib import Path
import sys

dsu_path = Path(sys.argv[1])
wiimote_path = Path(sys.argv[2])

old_start = '''void Start() {
    if (running.load()) return;
    if ((SDL_WasInit(SDL_INIT_JOYSTICK) & SDL_INIT_JOYSTICK) == 0) {
        RT_LOG(RT_TAG_RUNTIME) << "DSU client: SDL joystick subsystem is not initialized" << std::endl;
        return;
    }
'''
new_start = '''void Start() {
    if (running.load()) return;
    const SDL_InitFlags required = SDL_INIT_JOYSTICK | SDL_INIT_GAMEPAD;
    const SDL_InitFlags initialized = SDL_WasInit(required);
    const SDL_InitFlags missing = required & ~initialized;
    if (missing != 0 && !SDL_InitSubSystem(missing)) {
        RT_LOG(RT_TAG_RUNTIME) << "DSU client: SDL_InitSubSystem a échoué (flags=0x"
                               << std::hex << missing << std::dec << "): " << SDL_GetError() << std::endl;
        return;
    }
    RT_LOG(RT_TAG_RUNTIME) << "DSU client: SDL joystick="
                           << ((SDL_WasInit(SDL_INIT_JOYSTICK) & SDL_INIT_JOYSTICK) ? "actif" : "inactif")
                           << " gamepad="
                           << ((SDL_WasInit(SDL_INIT_GAMEPAD) & SDL_INIT_GAMEPAD) ? "actif" : "inactif")
                           << std::endl;
'''

old_hint = '''    // The remotes belong to the game's Bluetooth stack: SDL must not open them
    // as gamepads (its own Wii driver, or the Linux kernel driver's evdev nodes).
    SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_WII, enabled ? "0" : "1");
'''
new_hint = '''    // Wii U Pro Controller input comes through the WiiU Pro DSU client. Letting
    // SDL's HIDAPI Wii driver claim the Bluetooth device makes macOS disconnect
    // it as soon as the game starts. The dedicated Wiimote host below remains
    // available when Wii Remote support is enabled.
    SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_WII, "0");
'''

def prepare_update(path: Path, old: str, new: str, description: str):
    content = path.read_text()
    if new in content:
        print(f"Already patched: {description}")
        return None
    count = content.count(old)
    if count != 1:
        raise SystemExit(
            f"Cannot safely patch {path}: expected one known {description} block, found {count}. "
            "No source file was changed. Check whether WiiCompiled updated its runtime."
        )
    return (path, content.replace(old, new, 1), description)

updates = [
    prepare_update(dsu_path, old_start, new_start, "DSU SDL joystick/gamepad initialization"),
    prepare_update(wiimote_path, old_hint, new_hint, "SDL Wii HIDAPI ownership hint"),
]
for update in updates:
    if update is not None:
        path, content, description = update
        path.write_text(content)
        print(f"Patched: {description}")
PY

if ((patch_only)); then
    echo "Patch applied. Source files are backed up at: $backup_dir"
    exit 0
fi

case "$(uname -m)" in
    arm64|x86_64) ;;
    *) echo "Unsupported Mac architecture: $(uname -m)" >&2; exit 1 ;;
esac

if [[ -x "/Applications/WiiCompiled Setup.app/Contents/Resources/tools/cmake/bin/cmake" ]]; then
    cmake_bin="/Applications/WiiCompiled Setup.app/Contents/Resources/tools/cmake/bin/cmake"
elif command -v cmake >/dev/null 2>&1; then
    cmake_bin="$(command -v cmake)"
else
    echo "CMake was not found. Install WiiCompiled Setup or put cmake on PATH." >&2
    exit 1
fi

[[ -f "$build_dir/CMakeCache.txt" ]] || {
    echo "Configured build directory not found: $build_dir" >&2
    echo "Build Retro Rewind once with WiiCompiled Setup, then run this helper again." >&2
    exit 1
}
[[ -x "$publisher" ]] || { echo "App publisher not found: $publisher" >&2; exit 1; }
[[ ! -e "$output_dir/RetroRewind.app" ]] || {
    echo "Refusing to overwrite existing app: $output_dir/RetroRewind.app" >&2
    echo "Choose a new --output-dir." >&2
    exit 1
}

echo "Building RetroRewind for $(uname -m)..."
"$cmake_bin" --build "$build_dir" --target RetroRewind -j "${JOBS:-4}"

mkdir -p "$output_dir"
"$publisher" \
    --build-dir "$build_dir" \
    --product RetroRewind \
    --output-dir "$output_dir" \
    --architecture "$(uname -m)"

codesign --verify --deep --strict "$output_dir/RetroRewind.app"
echo "Ready: $output_dir/RetroRewind.app"
echo "Source backup: $backup_dir"
