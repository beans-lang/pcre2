# pcre2

PCRE2 10.47 for Beans — the regex engine behind grep, Apache and R,
compiled into your build from pinned, checksummed source. Unicode-aware
by default, no system packages on any OS.

```beans
import pcre2

fn main() {
    let word: pcre2.Regex = pcre2.Regex.compile("[a-z]+").expect("compile")
    match word.find("   beans compile fast   ") {
        some(span) => io.println("'{span.text}' at {span.start}..{span.end}"),
        none => io.println("no match"),
    }
}
```

Add it to a project:

```
beansc pot add github.com/beans-lang/pcre2 v0.1.0
```

## The shape of the API

| surface | job |
|---|---|
| `Regex.compile` / `compile_caseless` | compile once (UTF + Unicode properties on); errors name the byte that broke the pattern |
| `is_match`, `find`, `find_at` | boolean test, first match as a `Span` (start, end, text), walk-all-matches loops |
| `captures` | every group copied out as strings — index 0 is the whole match |
| `group_index(name)` | named group → capture index, for `(?<name>...)` patterns |

The compiled pattern and each call's scratch space free themselves in
`deinit`; matched text is copied out before any call returns, so nothing
you hold points into PCRE2's buffers.

`examples/parse_logs.b` is the real-world loop: one pattern with named
groups pulling ip/method/path/status out of access-log lines, with
unparseable lines counted instead of crashing anything.

## Layout

| path | what |
|---|---|
| `regex.b` | the whole hand-written layer |
| `sys/sys.b` | generated bindings — 237/237 functions at width 8 (`SKIPPED.md`) |
| `src/beans_pcre2_prelude.h` + `src/beans_*.c` | one wrapper per upstream translation unit; the prelude holds every build choice |
| `vendor/` | upstream `src/` tree, pinned in `VENDOR.md` (three documented non-autotools renames) |
| `tests/`, `examples/` | golden matching suite; the log-parsing example (`./test.sh --native`) |

## License

Apache-2.0 for this package. PCRE2 itself is BSD-3-Clause with the
PCRE2 exception (`vendor/pcre2/LICENCE.md`).
