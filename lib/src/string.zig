const std = @import("std");
const main = @import("main.zig");

const Mode = enum {
    scanning,
    char,
    escaped_char,
    unicode,
    end,
};

pub const StringParseResult = struct {
    skip: usize,
    token: main.StringToken,

    pub fn deinit(self: *StringParseResult, allocator: std.mem.Allocator) void {
        if (self.token.value) |value| {
            allocator.free(value);
        }
    }
};

pub fn parse(allocator: std.mem.Allocator, expression: []const u8) main.JsonError!StringParseResult {
    var mode = Mode.scanning;
    var pos: usize = 0;
    var value = std.ArrayList(u8){};
    defer value.deinit(allocator);

    while (pos < expression.len and mode != .end) {
        const ch = expression[pos];

        switch (mode) {
            .scanning => {
                if (std.ascii.isWhitespace(ch)) {
                    pos += 1;
                } else if (ch == '"') {
                    pos += 1;
                    mode = .char;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .char => {
                if (ch == '\\') {
                    pos += 1;
                    mode = .escaped_char;
                } else if (ch == '"') {
                    pos += 1;
                    mode = .end;
                } else if (ch != '\n' and ch != '\r') {
                    try value.append(allocator, ch);
                    pos += 1;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .escaped_char => {
                if (ch == '"' or ch == '\\' or ch == '/') {
                    try value.append(allocator, ch);
                    pos += 1;
                    mode = .char;
                } else if (ch == 'b') {
                    try value.append(allocator, '\x08'); // backspace
                    pos += 1;
                    mode = .char;
                } else if (ch == 'f') {
                    try value.append(allocator, '\x0C'); // form feed
                    pos += 1;
                    mode = .char;
                } else if (ch == 'n') {
                    try value.append(allocator, '\n');
                    pos += 1;
                    mode = .char;
                } else if (ch == 'r') {
                    try value.append(allocator, '\r');
                    pos += 1;
                    mode = .char;
                } else if (ch == 't') {
                    try value.append(allocator, '\t');
                    pos += 1;
                    mode = .char;
                } else if (ch == 'u') {
                    pos += 1;
                    mode = .unicode;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .unicode => {
                if (pos + 4 > expression.len) {
                    return main.JsonError.IncompleteExpression;
                }

                const slice = expression[pos .. pos + 4];
                const hex_value = std.fmt.parseInt(u16, slice, 16) catch {
                    return main.JsonError.UnexpectedCharacter;
                };

                // Convert unicode codepoint to UTF-8
                var utf8_buf: [4]u8 = undefined;
                const utf8_len = std.unicode.utf8Encode(hex_value, &utf8_buf) catch {
                    return main.JsonError.UnexpectedCharacter;
                };

                try value.appendSlice(allocator, utf8_buf[0..utf8_len]);
                pos += 4;
                mode = .char;
            },
            .end => break,
        }
    }

    if (mode != .end) {
        return main.JsonError.IncompleteExpression;
    }

    const owned_value = try allocator.dupe(u8, value.items);

    return StringParseResult{
        .skip = pos,
        .token = main.StringToken{
            .value = owned_value,
        },
    };
}
