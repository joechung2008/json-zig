const std = @import("std");
const main = @import("main.zig");
const string = @import("string.zig");
const value = @import("value.zig");

const Mode = enum {
    scanning,
    string,
    colon,
    value,
    end,
};

pub const PairParseResult = struct {
    skip: usize,
    token: main.PairToken,

    pub fn deinit(self: *PairParseResult, allocator: std.mem.Allocator) void {
        if (self.token.key) |key| {
            if (key.value) |key_value| {
                allocator.free(key_value);
            }
        }
        if (self.token.value) |*val| {
            val.deinit();
        }
    }
};

pub fn parse(allocator: std.mem.Allocator, expression: []const u8, delimiters: ?[]const u8) main.JsonError!PairParseResult {
    var mode = Mode.scanning;
    var pos: usize = 0;
    var token = main.PairToken{
        .key = null,
        .value = null,
    };

    while (pos < expression.len and mode != .end) {
        const ch = expression[pos];

        switch (mode) {
            .scanning => {
                if (std.ascii.isWhitespace(ch)) {
                    pos += 1;
                } else {
                    mode = .string;
                }
            },
            .string => {
                const slice = expression[pos..];
                const result = try string.parse(allocator, slice);
                token.key = result.token;
                pos += result.skip;
                mode = .colon;
            },
            .colon => {
                if (std.ascii.isWhitespace(ch)) {
                    pos += 1;
                } else if (ch == ':') {
                    pos += 1;
                    mode = .value;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .value => {
                const slice = expression[pos..];
                const result = try value.parse(allocator, slice, delimiters);
                token.value = result.token;
                pos += result.skip;
                mode = .end;
            },
            .end => break,
        }
    }

    if (mode != .end) {
        return main.JsonError.IncompleteExpression;
    }

    return PairParseResult{
        .skip = pos,
        .token = token,
    };
}
