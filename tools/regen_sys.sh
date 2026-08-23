#!/usr/bin/env bash
# Regenerates sys/sys.b and reports drift between the vendored tree and
# the single-TU include list. Run after a vendor upgrade.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BEANSC=${BEANSC:-$(command -v beansc)}

"$BEANSC" bindgen "$ROOT/vendor/pcre2/src/pcre2.h" -o "$ROOT/sys/sys.b" \
    --package sys --pub --allow-unsupported -- -DPCRE2_CODE_UNIT_WIDTH=8 -DPCRE2_STATIC

echo "bound $(grep -c 'extern "C" fn' "$ROOT/sys/sys.b") functions; skips:"
grep '^// skipped' "$ROOT/sys/sys.b" || echo "  none"

echo "vendored .c files with no wrapper in src/ :"
for f in "$ROOT"/vendor/pcre2/src/pcre2_*.c; do
    base=$(basename "$f"); name=${base#pcre2_}
    [ -f "$ROOT/src/beans_$name" ] || echo "  $base"
done
