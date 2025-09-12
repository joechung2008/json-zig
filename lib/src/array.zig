const std = @import("std");
const main = @import("main.zig");
const value = @import("value.zig");

const Mode = enum {
    scanning,
    elements,
    comma,
    end,
};

pub const ArrayParseResult = struct {
    skip: usize,
    token: main.ArrayToken,

    pub fn deinit(self: *ArrayParseResult, allocator: std.mem.Allocator) void {
        for (self.token.values.items) |*val| {
            val.deinit();
        }
        self.token.values.deinit();
        _ = allocator;
    }
};

pub fn parse(allocator: std.mem.Allocator, expression: []const u8) main.JsonError!ArrayParseResult {
    var mode = Mode.scanning;
    var pos: usize = 0;
    var token = main.ArrayToken{
        .values = std.ArrayList(main.ValueToken){},
    };

    while (pos < expression.len and mode != .end) {
        const ch = expression[pos];

        switch (mode) {
            .scanning => {
                if (std.ascii.isWhitespace(ch)) {
                    pos += 1;
                } else if (ch == '[') {
                    pos += 1;
                    mode = .elements;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .elements => {
                if (std.ascii.isWhitespace(ch)) {
                    pos += 1;
                } else if (ch == ']') {
                    if (token.values.items.len > 0) {
                        return main.JsonError.UnexpectedCharacter; // Trailing comma
                    }
                    pos += 1;
                    mode = .end;
                } else {
                    const slice = expression[pos..];
                    const delimiter_chars = " \n\r\t],";
                    const result = try value.parse(allocator, slice, delimiter_chars);
                    if (result.token) |val_token| {
                        try token.values.append(allocator, val_token);
                    }
                    pos += result.skip;
                    mode = .comma;
                }
            },
            .comma => {
                if (std.ascii.isWhitespace(ch)) {
                    pos += 1;
                } else if (ch == ']') {
                    pos += 1;
                    mode = .end;
                } else if (ch == ',') {
                    pos += 1;
                    mode = .elements;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .end => break,
        }
    }

    if (mode != .end) {
        return main.JsonError.IncompleteExpression;
    }

    return ArrayParseResult{
        .skip = pos,
        .token = token,
    };
}
