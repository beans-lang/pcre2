// The real-world shape: pull structured fields out of web-server access
// log lines with one compiled pattern and named groups.
//
//     beansc run examples/parse_logs.b
package main

import pcre2
import std.io

fn main() {
    let line_format: pcre2.Regex = pcre2.Regex.compile("^(?<ip>[0-9.]+) \\S+ \\S+ \\[(?<when>[^\\]]+)\\] \"(?<method>[A-Z]+) (?<path>\\S+) [^\"]*\" (?<status>[0-9]\{3\}) (?<size>[0-9]+)").expect("compile log format")

    var lines: List<string> = [
        "203.0.113.9 - - [23/Aug/2026:10:00:01 +0800] \"GET /api/users HTTP/1.1\" 200 5320",
        "198.51.100.4 - - [23/Aug/2026:10:00:02 +0800] \"POST /api/orders HTTP/1.1\" 201 88",
        "203.0.113.9 - - [23/Aug/2026:10:00:07 +0800] \"GET /api/missing HTTP/1.1\" 404 153",
        "not a log line at all",
    ]

    let ip_at: int = line_format.group_index("ip").expect("ip group")
    let method_at: int = line_format.group_index("method").expect("method group")
    let path_at: int = line_format.group_index("path").expect("path group")
    let status_at: int = line_format.group_index("status").expect("status group")

    var parsed: int = 0
    var errors: int = 0
    for line: string in lines {
        match line_format.captures(line) {
            some(fields) => {
                parsed = parsed + 1
                io.println("{fields[status_at]} {fields[method_at]:4} {fields[path_at]} from {fields[ip_at]}")
            }
            none => {
                errors = errors + 1
                io.println("unparseable: {line}")
            }
        }
    }
    io.println("parsed {parsed}, rejected {errors}")
}
