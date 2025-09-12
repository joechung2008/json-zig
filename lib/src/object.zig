const std = @import("std");
const main = @import("main.zig");
const pair = @import("pair.zig");

const Mode = enum {
    scanning,
    pair,
    delimiter,
    end,
};

pub const ObjectParseResult = struct {
    skip: usize,
    token: main.ObjectToken,

    pub fn deinit(self: *ObjectParseResult, allocator: std.mem.Allocator) void {
        for (self.token.members.items) |*member| {
            if (member.key) |key| {
                if (key.value) |key_value| {
                    allocator.free(key_value);
                }
            }
            if (member.value) |*val| {
                val.deinit();
            }
        }
        self.token.members.deinit();
    }
};

pub fn parse(allocator: std.mem.Allocator, expression: []const u8) main.JsonError!ObjectParseResult {
    var mode = Mode.scanning;
    var pos: usize = 0;
    var members = std.ArrayList(main.PairToken){};

    while (pos < expression.len and mode != .end) {
        const ch = expression[pos];

        switch (mode) {
            .scanning => {
                if (std.ascii.isWhitespace(ch)) {
                    pos += 1;
                } else if (ch == '{') {
                    pos += 1;
                    mode = .pair;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .pair => {
                if (std.ascii.isWhitespace(ch)) {
                    pos += 1;
                } else if (ch == '}') {
                    if (members.items.len > 0) {
                        return main.JsonError.UnexpectedCharacter; // Trailing comma
                    }
                    pos += 1;
                    mode = .end;
                } else {
                    const slice = expression[pos..];
                    const delimiter_chars = " \n\r\t},";
                    const result = try pair.parse(allocator, slice, delimiter_chars);
                    try members.append(allocator, result.token);
                    pos += result.skip;
                    mode = .delimiter;
                }
            },
            .delimiter => {
                if (std.ascii.isWhitespace(ch)) {
                    pos += 1;
                } else if (ch == ',') {
                    pos += 1;
                    mode = .pair;
                } else if (ch == '}') {
                    pos += 1;
                    mode = .end;
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

    return ObjectParseResult{
        .skip = pos,
        .token = main.ObjectToken{
            .members = members,
        },
    };
}
