# Coverage: what is not bound, and why

`sys/sys.b` binds **237 of 237** public functions in the vendored
`pcre2.h` at code unit width 8 — zero skip comments.

Surface choices, not binding gaps:

- Only the 8-bit API is compiled and bound (`_8` suffix). The 16- and
  32-bit widths triple the build for code units Beans strings never
  produce; they can join as separate packages if ever wanted.
- JIT stays off (`pcre2_jit_compile.c` compiles to its documented stub):
  portable behavior everywhere first. The interpreter engine is what the
  tests pin.
- The POSIX compatibility shim (`pcre2posix.*`) is not vendored — it
  exists for C programs porting from `<regex.h>`.
- Option bits and error codes are `#define`s, invisible to a generated
  binding; the ones the wrapper uses are restated in `regex.b` with
  their frozen values (UTF, UCP, CASELESS; INFO and CONFIG selectors).
