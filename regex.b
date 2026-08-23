// PCRE2 for Beans — compile once, match many, read captures by number
// or name. Everything the caller touches is a Beans value: matched text
// is copied out, spans are plain ints, and both the compiled pattern
// and its scratch space free themselves in deinit.
package pcre2

import pcre2.sys

// PCRE2 constants this layer needs, restated from pcre2.h (they are
// #defines, invisible to a generated binding; values are ABI-frozen):
// PCRE2_CASELESS 0x8, PCRE2_MULTILINE 0x400, PCRE2_DOTALL 0x20,
// PCRE2_ERROR_NOMATCH -1, PCRE2_INFO_NAMECOUNT 17.

fn error_text(code: int) -> string {
    var buffer: Bytes = new Bytes(256)
    var written: int = 0
    unsafe {
        written = sys.pcre2_get_error_message_8(
            code as i32, buffer.as_ptr(), buffer.len() as u64) as int
    }
    if written < 0 {
        return "pcre2 error {code}"
    }
    buffer.resize(written)
    return buffer.to_string()
}

/// The vendored PCRE2 version, e.g. "10.47".
pub fn version() -> string {
    var buffer: Bytes = new Bytes(64)
    var written: int = 0
    unsafe {
        // PCRE2_CONFIG_VERSION = 11.
        written = sys.pcre2_config_8(11 as u32, buffer.as_ptr()) as int
    }
    if written <= 0 {
        return ""
    }
    // The count includes the trailing NUL.
    buffer.resize(written - 1)
    return buffer.to_string()
}

/// One match: where it sits in the subject, and the matched text.
pub class Span {
    pub start: int = 0
    pub end: int = 0
    pub text: string = ""

    fn init(start: int, end: int, text: string) {
        self.start = start
        self.end = end
        self.text = text
    }
}

/// A compiled pattern. Compile once, use from one thread at a time;
/// freed by `deinit`.
pub class Regex {
    code: RawPtr<sys.Pcre2Code8> = RawPtr.null()
    live: bool = false

    fn init(code: RawPtr<sys.Pcre2Code8>) {
        self.code = code
        self.live = true
    }

    fn deinit() {
        if self.live {
            self.live = false
            unsafe {
                sys.pcre2_code_free_8(self.code)
            }
        }
    }

    /// Compiles `pattern` (UTF-8, Unicode-aware).
    pub static fn compile(pattern: string) -> Result<Regex> {
        return compile_with(pattern, 0)
    }

    /// Compiles `pattern` case-insensitively.
    pub static fn compile_caseless(pattern: string) -> Result<Regex> {
        // PCRE2_CASELESS
        return compile_with(pattern, 8)
    }

    /// True when the pattern matches anywhere in `text`.
    pub fn is_match(text: string) -> bool {
        match self.find_at(text, 0) {
            some(span) => { return true }
            none => { return false }
        }
    }

    /// The first match in `text`, or `none`.
    pub fn find(text: string) -> Option<Span> {
        return self.find_at(text, 0)
    }

    /// The first match at or after byte offset `from`, or `none` —
    /// step a loop with `span.end` to walk every match.
    pub fn find_at(text: string, from: int) -> Option<Span> {
        if !self.live || from < 0 || from > text.len() {
            return none
        }
        var subject: Bytes = Bytes.from(text)
        subject.push(0)
        var start: int = -1
        var finish: int = -1
        unsafe {
            let no_general: RawPtr<sys.Pcre2GeneralContext8> = RawPtr.null()
            let data: RawPtr<sys.Pcre2MatchData8> =
                sys.pcre2_match_data_create_from_pattern_8(self.code, no_general)
            if data.is_null() {
                return none
            }
            let no_match_ctx: RawPtr<sys.Pcre2MatchContext8> = RawPtr.null()
            let status: int = sys.pcre2_match_8(
                self.code, subject.as_ptr(), text.len() as u64,
                from as u64, 0 as u32, data, no_match_ctx) as int
            if status > 0 {
                let ovector: RawPtr<u64> = sys.pcre2_get_ovector_pointer_8(data)
                start = ovector.read() as int
                finish = ovector.offset(1).read() as int
            }
            sys.pcre2_match_data_free_8(data)
        }
        if start < 0 {
            return none
        }
        let piece: Bytes = subject.slice(start, finish)
        return some(new Span(start, finish, piece.to_string()))
    }

    /// The first match with every capture group copied out: index 0 is
    /// the whole match, then one string per group (unset groups read
    /// as ""). `none` when the pattern does not match.
    pub fn captures(text: string) -> Option<List<string>> {
        if !self.live {
            return none
        }
        var subject: Bytes = Bytes.from(text)
        subject.push(0)
        var pieces: List<string> = []
        var matched: bool = false
        unsafe {
            let no_general: RawPtr<sys.Pcre2GeneralContext8> = RawPtr.null()
            let data: RawPtr<sys.Pcre2MatchData8> =
                sys.pcre2_match_data_create_from_pattern_8(self.code, no_general)
            if data.is_null() {
                return none
            }
            let no_match_ctx: RawPtr<sys.Pcre2MatchContext8> = RawPtr.null()
            let status: int = sys.pcre2_match_8(
                self.code, subject.as_ptr(), text.len() as u64,
                0 as u64, 0 as u32, data, no_match_ctx) as int
            if status > 0 {
                matched = true
                let ovector: RawPtr<u64> = sys.pcre2_get_ovector_pointer_8(data)
                let pairs: int = sys.pcre2_get_ovector_count_8(data) as int
                for index: int in 0..pairs {
                    let piece_start: int = ovector.offset(index * 2).read() as int
                    let piece_end: int = ovector.offset(index * 2 + 1).read() as int
                    if piece_start > text.len() || piece_end > text.len() ||
                       piece_start < 0 || piece_end < piece_start {
                        // PCRE2_UNSET: the group took no part in the match.
                        pieces.push("")
                    } else {
                        let piece: Bytes = subject.slice(piece_start, piece_end)
                        pieces.push(piece.to_string())
                    }
                }
            }
            sys.pcre2_match_data_free_8(data)
        }
        if !matched {
            return none
        }
        return some(move pieces)
    }

    /// The capture index for a named group, or `none` when the pattern
    /// has no such name. Use it to index into `captures` output.
    pub fn group_index(name: string) -> Option<int> {
        if !self.live {
            return none
        }
        var name_buf: Bytes = Bytes.from(name)
        name_buf.push(0)
        var index: int = -1
        unsafe {
            index = sys.pcre2_substring_number_from_name_8(
                self.code, name_buf.as_ptr()) as int
        }
        if index < 0 {
            return none
        }
        return some(index)
    }
}

// Shared compile path for the option variants.
fn compile_with(pattern: string, options: int) -> Result<Regex> {
    var pattern_buf: Bytes = Bytes.from(pattern)
    pattern_buf.push(0)
    var code: RawPtr<sys.Pcre2Code8> = RawPtr.null()
    var status: int = 0
    var where_at: int = 0
    unsafe {
        let error_code: RawPtr<i32> = RawPtr.alloc(1)
        let error_offset: RawPtr<u64> = RawPtr.alloc(1)
        let no_compile_ctx: RawPtr<sys.Pcre2CompileContext8> = RawPtr.null()
        // PCRE2_UTF (0x80000) | PCRE2_UCP (0x20000): Unicode-aware by
        // default, matching how every modern engine ships.
        let flags: u32 = (options + 524288 + 131072) as u32
        code = sys.pcre2_compile_8(
            pattern_buf.as_ptr(), pattern.len() as u64, flags,
            error_code, error_offset, no_compile_ctx)
        status = error_code.read() as int
        where_at = error_offset.read() as int
        error_code.free()
        error_offset.free()
    }
    if code.is_null() {
        let detail: string = error_text(status)
        return err("compile: {detail} at byte {where_at} of the pattern", "invalid")
    }
    return ok(new Regex(code))
}
