#!/usr/bin/env bash
# Blitzsprecher — lokaler Build nach dem Blitztext-Vorbild.
#
# Nutzung:
#   ./build.sh              # xcodegen + Debug-Build
#   ./build.sh --run        # zusätzlich die gebaute App starten
#   ./build.sh --clean      # vorher aufräumen
#
# Erzeugt eine ad-hoc signierte Debug-App im DerivedData-Verzeichnis.
# Für Veröffentlichung braucht es eigene Signierung und Notarisierung.
set -euo pipefail

cd "$(dirname "$0")"

# PATH-Falle vermeiden (siehe Memory reference_exportarchive_path.md):
# fremde Homebrew-Tools dürfen hier nicht in die Toolchain reingrätschen.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"

CLEAN=0
RUN=0
for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=1 ;;
    --run)   RUN=1 ;;
    *) echo "Unbekanntes Argument: $arg" >&2; exit 2 ;;
  esac
done

command -v xcodegen >/dev/null || { echo "Fehlt: xcodegen (brew install xcodegen)"; exit 1; }
command -v xcodebuild >/dev/null || { echo "Fehlt: xcodebuild (Xcode installieren)"; exit 1; }

echo "→ xcodegen generate"
xcodegen generate

if [ "$CLEAN" = 1 ]; then
  echo "→ xcodebuild clean"
  xcodebuild clean -scheme Blitzsprecher -quiet
fi

echo "→ xcodebuild build (Debug)"
xcodebuild build \
  -scheme Blitzsprecher \
  -configuration Debug \
  -destination 'platform=macOS' \
  -quiet \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

APP_PATH="$(xcodebuild -showBuildSettings -scheme Blitzsprecher -configuration Debug 2>/dev/null | awk -F' = ' '/^ *BUILT_PRODUCTS_DIR/ {print $2}' | head -n 1)/Blitzsprecher.app"

echo "✓ Gebaut: $APP_PATH"

if [ "$RUN" = 1 ]; then
  echo "→ Starten"
  open "$APP_PATH"
fi
