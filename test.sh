#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)

if [[ -z ${BEANS_ROOT:-} && -x "$ROOT/../../beans/build/beansc" ]]; then
    BEANS_ROOT=$(cd "$ROOT/../../beans" && pwd)
fi
if [[ -z ${BEANSC:-} ]]; then
    if [[ -n ${BEANS_ROOT:-} && -x "$BEANS_ROOT/build/beansc" ]]; then
        BEANSC="$BEANS_ROOT/build/beansc"
    else
        BEANSC=$(command -v beansc || true)
    fi
fi

# Windows launchers are .cmd files, which Git Bash can run but never
# marks executable — an existing file is enough there.
if [[ -z "$BEANSC" ]] || [[ ! -x "$BEANSC" && ! -f "$BEANSC" ]]; then
    echo "beansc not found: set BEANSC, set BEANS_ROOT, or put beansc on PATH" >&2
    exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if [[ -n ${BEANS_ROOT:-} && "$BEANSC" == "$BEANS_ROOT/build/beansc" ]]; then
    cd "$BEANS_ROOT"
fi

cases=(matching)
for name in "${cases[@]}"; do
    "$BEANSC" run "$ROOT/tests/$name.b" >"$tmp/$name.interp"
    diff -u "$ROOT/tests/$name.out" "$tmp/$name.interp"
done

# The example's output is fully deterministic; hold it to its own text.
"$BEANSC" run "$ROOT/examples/parse_logs.b" >"$tmp/example.out"
grep -q "parsed 3, rejected 1" "$tmp/example.out"

for target in x86_64-unknown-linux-gnu x86_64-pc-windows-gnu aarch64-unknown-linux-musl; do
    "$BEANSC" check "$ROOT/tests/matching.b" --target "$target" >/dev/null
done

if [[ ${1:-} == "--native" ]]; then
    for name in "${cases[@]}"; do
        "$BEANSC" build "$ROOT/tests/$name.b" -o "$tmp/$name.bin" >/dev/null
        "$tmp/$name.bin" >"$tmp/$name.native"
        diff -u "$ROOT/tests/$name.out" "$tmp/$name.native"
    done
fi

echo "ok pcre2: interpreter, example, target checks${1:+, native}"
