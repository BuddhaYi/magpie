#!/usr/bin/env bash
# install.sh — symlink tx into your PATH
set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tx"

if [[ ! -f "$SOURCE" ]]; then
    echo "tx not found at $SOURCE" >&2
    exit 1
fi

# Pick install location (first writable PATH entry)
candidates=(
    "$HOME/.local/bin"
    "/usr/local/bin"
    "$HOME/bin"
)
target=""
for dir in "${candidates[@]}"; do
    if [[ -d "$dir" && -w "$dir" ]]; then
        target="$dir"
        break
    fi
done

if [[ -z "$target" ]]; then
    echo "no writable bin directory found in:" >&2
    printf '  %s\n' "${candidates[@]}" >&2
    echo ""
    echo "create one (e.g. mkdir -p ~/.local/bin) and add it to your PATH, then re-run." >&2
    exit 1
fi

# Verify Python 3.10+
if ! command -v python3 >/dev/null; then
    echo "python3 not found — install Python 3.10+ first" >&2
    exit 1
fi

# Verify upstream tools
missing=()
command -v twitter  >/dev/null || missing+=("twitter-cli (uv tool install twitter-cli  OR  pipx install twitter-cli)")
command -v bird     >/dev/null || missing+=("bird (npm i -g @steipete/bird)")
command -v opencli  >/dev/null || missing+=("opencli (npm i -g @jackwener/opencli)")

if (( ${#missing[@]} > 0 )); then
    echo "warning: missing upstream tools — magpie won't work until you install them:" >&2
    printf '  - %s\n' "${missing[@]}" >&2
    echo ""
fi

# Symlink (overwrite if exists)
ln -sf "$SOURCE" "$target/tx"
chmod +x "$SOURCE"

echo "✓ installed: $target/tx → $SOURCE"
echo ""
echo "next steps:"
echo "  1. tx --refresh           # build command discovery cache"
echo "  2. tx cookies-save        # extract X cookies (interactive, one-time Keychain prompt)"
echo "  3. tx auth                # verify everything is green"
echo "  4. tx help                # see what you can do"
