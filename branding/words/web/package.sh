#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
. "$ROOT/packaging/env.sh"
(cd "$ROOT/apps/wordcraft-web" && trunk build --release)
test -f "$ROOT/dist/web/index.html"
mkdir -p "$ROOT/dist/web/legal"
for file in LICENSE-MIT LICENSE-APACHE NOTICE ATTRIBUTION.md; do
  cp "$ROOT/$file" "$ROOT/dist/web/legal/"
done
OUT="$DIST/Words-$VERSION-Web.zip"
(cd "$ROOT/dist/web" && zip -qr "$OUT" .)
echo "Created $OUT"
