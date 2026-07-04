#!/usr/bin/env bash
# Symlink the latexdiff-pdf engine onto your PATH as `tdiff`.
# Usage: ./install.sh [target-dir]   (default: ~/.local/bin)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/scripts/latexdiff-pdf.sh"
DEST_DIR="${1:-$HOME/.local/bin}"
NAME="tdiff"
LINK="$DEST_DIR/$NAME"

[ -f "$SRC" ] || { echo "install: engine not found: $SRC" >&2; exit 1; }
mkdir -p "$DEST_DIR"
chmod +x "$SRC"
ln -sf "$SRC" "$LINK"
echo "linked $LINK -> $SRC"

case ":$PATH:" in
  *":$DEST_DIR:"*) echo "run it from any git LaTeX project: $NAME <old-git-ref>" ;;
  *) echo "note: $DEST_DIR is not on your PATH; add it, e.g.:"
     echo "  echo 'export PATH=\"$DEST_DIR:\$PATH\"' >> ~/.zshrc" ;;
esac
