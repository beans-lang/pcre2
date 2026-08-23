# Changelog

## v0.1.0 — 2026-08-23

- Initial release: PCRE2 10.47 vendored (pinned + checksummed), 8-bit
  width, Unicode on, JIT off, one wrapper TU per upstream source.
- 237/237 public functions bound; zero bindgen skips.
- Regex/Span wrapper with deinit-owned pattern and scratch space,
  copy-out matches, numbered and named captures, byte-precise compile
  errors.
- Golden matching suite (validation, spans, walk-all, captures, unset
  groups, Unicode incl. combining marks, bad patterns) plus an
  access-log parsing example with named groups.
