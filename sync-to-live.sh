#!/usr/bin/env bash
# Copies safe-to-sync files under .config/ from this repo checkout into
# ~/.config, then reloads Hyprland and hot-reloads Quickshell. For iterating
# on the dotfiles without the manual "diff, cp, restart quickshell" dance.
#
# "Safe" = git-tracked under .config/ AND not one of the paths .gitignore
# flags as machine-generated (settings.conf, autostart.conf, env.conf,
# keybindings.conf, monitors.conf - each has a matching .template that
# settings_watcher.sh expands per-machine at runtime). Those 5 files are
# gitignored but were already committed before that, so .gitignore alone
# doesn't stop `git ls-files` from listing them - we exclude them explicitly
# by reading .gitignore's .config/ entries, so blindly copying never
# clobbers your live, correctly-generated Hyprland config with a stale
# repo snapshot.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$REPO_DIR/.git" ]; then
    echo "error: $REPO_DIR doesn't look like a git checkout" >&2
    exit 1
fi

cd "$REPO_DIR"

EXCLUDE_ARGS=()
while IFS= read -r p; do
    EXCLUDE_ARGS+=(":!$p")
done < <(grep -E '^\.config/' .gitignore || true)

echo "==> Syncing safe .config/ files to \$HOME..."
if [ "${#EXCLUDE_ARGS[@]}" -gt 0 ]; then
    echo "    (skipping machine-generated files: ${EXCLUDE_ARGS[*]#:!})"
fi
CHANGED=0
CHECKED=0
while IFS= read -r f; do
    CHECKED=$((CHECKED + 1))
    src="$REPO_DIR/$f"
    dst="$HOME/$f"
    if ! cmp -s "$src" "$dst" 2>/dev/null; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "  updated: $f"
        CHANGED=$((CHANGED + 1))
    fi
done < <(git ls-files -- .config "${EXCLUDE_ARGS[@]}")
echo "==> Checked $CHECKED safe-to-sync files, updated $CHANGED."

echo "==> Reloading Hyprland config..."
hyprctl reload >/dev/null

SHELL_QML="$HOME/.config/hypr/scripts/quickshell/Shell.qml"
if pgrep -f "quickshell.*Shell.qml" >/dev/null; then
    echo "==> Hot-reloading Quickshell..."
    qs -p "$SHELL_QML" ipc call main forceReload >/dev/null 2>&1
else
    echo "==> Quickshell isn't running, launching it..."
    quickshell -p "$SHELL_QML" >/dev/null 2>&1 &
    disown
fi

echo "==> Done."
