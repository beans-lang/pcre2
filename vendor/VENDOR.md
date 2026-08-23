# Vendored: PCRE2

| field | value |
|---|---|
| version | 10.47 |
| source | https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.47/pcre2-10.47.tar.gz |
| archive SHA-256 | `c08ae2388ef333e8403e670ad70c0a11f1eed021fd88308d7e02f596fcd9dc16` |
| license | BSD-3-Clause with the PCRE2 exception (`pcre2/LICENCE.md`) |

## Inventory

`pcre2/src` is the release tarball's `src/` tree limited to the library:
the test programs (`pcre2_jit_test.c`, `pcre2_printint.c`,
`pcre2_fuzzsupport.c`), the table generator (`pcre2_dftables.c`), the
POSIX shim (`pcre2posix.*`), the EBCDIC chartables variants and the
build-system inputs (`*.sym`, `*.h.in`) are not vendored.

Three files are upstream's own non-autotools renames, copied verbatim
(this is the documented way to build PCRE2 without configure):

- `config.h` ← `config.h.generic`
- `pcre2.h` ← `pcre2.h.generic`
- `pcre2_chartables.c` ← `pcre2_chartables.c.dist`

All build choices live in `src/beans_pcre2_prelude.h`, never in the
vendor tree: code unit width 8, static linkage, Unicode support on.

## Upgrade

1. Download the new release tarball; verify and record its SHA-256.
2. Replace `pcre2/src` and `LICENCE.md`; re-apply the three renames and
   the exclusions; reconcile the wrapper list in `src/` (one wrapper per
   `pcre2_*.c`) and the csrc rows in `beans.pot`.
3. Regenerate `sys/sys.b` (`tools/regen_sys.sh`), update SKIPPED.md if
   the surface moved, run `./test.sh --native`.
