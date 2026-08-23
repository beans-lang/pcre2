// Real-world regex work: validation, spans, walking all matches,
// numbered and named captures, Unicode subjects, and compile errors
// that point at the byte that broke.
package main

import pcre2
import std.io

fn main() {
    io.println("version set {pcre2.version().len() > 0}")

    // Validation.
    let email: pcre2.Regex = pcre2.Regex.compile("^[a-z0-9._]+@[a-z0-9-]+\\.[a-z]\{2,\}$").expect("compile email")
    let good: bool = email.is_match("dev@beans-lang.org")
    let bad: bool = email.is_match("not-an-email")
    io.println("valid {good} invalid {bad}")

    // Case-insensitive variant.
    let hello: pcre2.Regex = pcre2.Regex.compile_caseless("^hello").expect("compile hello")
    let shouted: bool = hello.is_match("HeLLo world")
    io.println("caseless {shouted}")

    // Spans and walking every match.
    let word: pcre2.Regex = pcre2.Regex.compile("[a-z]+").expect("compile word")
    match word.find("   beans compile fast   ") {
        some(span) => io.println("first '{span.text}' at {span.start}..{span.end}"),
        none => io.println("first none"),
    }
    var found: int = 0
    var cursor: int = 0
    var walking: bool = true
    for walking {
        match word.find_at("   beans compile fast   ", cursor) {
            some(span) => {
                found = found + 1
                cursor = span.end
            }
            none => { walking = false }
        }
    }
    io.println("words {found}")

    // Numbered captures.
    let kv: pcre2.Regex = pcre2.Regex.compile("([a-z_]+)=([0-9]+)").expect("compile kv")
    match kv.captures("retries=5") {
        some(groups) => io.println("kv {groups[1]} -> {groups[2]} (of {groups.len()})"),
        none => io.println("kv none"),
    }

    // Unset trailing group reads as empty.
    let opt: pcre2.Regex = pcre2.Regex.compile("(a)(b)?").expect("compile opt")
    match opt.captures("a") {
        some(groups) => {
            let empty_group: bool = groups[2] == ""
            io.println("optional group empty {empty_group}")
        }
        none => io.println("optional none"),
    }

    // Unicode: match a word in any script — real Indic text carries
    // combining marks, so the letter class needs \p{M} beside \p{L}.
    let letters: pcre2.Regex = pcre2.Regex.compile("^[\\p\{L\}\\p\{M\}]+$").expect("compile letters")
    let bengali: bool = letters.is_match("চায়ের")
    let digits: bool = letters.is_match("1234")
    io.println("unicode {bengali} digits {digits}")

    // A bad pattern names the byte that broke it.
    match pcre2.Regex.compile("open(paren") {
        ok(bad) => io.println("bad pattern accepted"),
        err(error) => io.println("bad pattern refused {error.kind}"),
    }

    io.println("matching ok")
}
