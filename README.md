# json-zig

A JSON parser implementation in Zig 0.15.1.

## License

MIT

## Reference

[json.org](https://www.json.org/json-en.html)

## Quick Start

### Prerequisites

- Zig 0.15.1

### Building

```bash
# Clone the repository
git clone https://github.com/joechung2008/json-zig/json-zig.git
cd json-zig

# Build the project
zig build

# The CLI executable will be available at: ./zig-out/bin/cli
# The library will be available at: ./zig-out/lib/libshared.a or ./zig-out/lib/shared.lib
```

### Running Tests

```bash
# Run all tests (silent on success)
zig build test

# Run tests with detailed summary
zig build test --summary all

# Run with verbose build output
zig build test --verbose

# Run specific test by name
zig test lib/src/main.zig --test-filter "parse number"
```

Example output:

```bash
$ zig build test
# No output = all tests passed

$ zig build test --summary all
Build Summary: 3/3 steps succeeded; 68/68 tests passed
test success
└─ run test 68 passed 1ms MaxRSS:1M
  └─ compile test Debug native success 431ms MaxRSS:128M

$ zig test lib/src/main.zig
All 68 tests passed.
```

### Using the CLI

The CLI tool reads JSON from standard input and displays the parsed structure:

```bash
# Parse a simple number
echo '42' | ./zig-out/bin/cli

# Parse a string
echo '"hello world"' | ./zig-out/bin/cli

# Parse a complex object
echo '{"name": "Alice", "age": 30, "hobbies": ["reading", "coding"]}' | ./zig-out/bin/cli

# Parse from a file
cat data.json | ./zig-out/bin/cli

# Test error handling
echo '{"invalid": json}' | ./zig-out/bin/cli
```

### Example Output

```bash
$ echo '{"name": "Alice", "age": 30, "hobbies": ["reading", "coding"]}' | ./zig-out/bin/cli
Successfully parsed JSON:
Object (3 members):
  "name":
    String: "Alice"
  "age":
    Number: 30
  "hobbies":
    Array (2 elements):
      [0]:
        String: "reading"
      [1]:
        String: "coding"
```

## 📚 Using as a Library

```zig
const std = @import("std");
const json = @import("json-zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse JSON string
    var result = try json.parse(allocator, "{\"hello\": \"world\"}");
    defer result.deinit(allocator);

    // Access parsed data
    if (result.token) |token| {
        switch (token) {
            .object => |obj| {
                std.debug.print("Parsed object with {} members\n", .{obj.members.items.len});
            },
            else => {},
        }
    }
}
```

## ⚠️ Zig Language Server (zls) Compatibility Note

If you use the Zig Language Server (zls) for editor integration, be aware:

- As of this release, zls may only be available for Zig 0.15.0, not 0.15.1.
- Using zls built for 0.15.0 with Zig 0.15.1 can result in false positive warnings or incomplete diagnostics.
- If you encounter spurious warnings, either disable zls or temporarily use Zig 0.15.0 for best compatibility.
- Monitor the zls project for updates supporting Zig 0.15.1.

This does not affect building or running the project itself, only editor diagnostics and completions.
