/* Shared build configuration for every pcre2 translation unit. The
 * vendored config.h is the upstream config.h.generic verbatim; the
 * choices live here so the vendor copy stays a pure rename. */
#ifndef BEANS_PCRE2_PRELUDE_H
#define BEANS_PCRE2_PRELUDE_H
#define PCRE2_CODE_UNIT_WIDTH 8
#define PCRE2_STATIC 1
#define HAVE_CONFIG_H 1
#define SUPPORT_UNICODE 1
#endif
