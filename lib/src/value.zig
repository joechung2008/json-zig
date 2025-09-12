const std = @import("std");
const main = @import("main.zig");
const string = @import("string.zig");
const number = @import("number.zig");

// Forward declarations - these will be resolved when other modules are implemented
const array = @import("array.zig");
const object = @import("object.zig");

const Mode = enum {
    scanning,
    array,
    false,
    null,
    number,
    object,
    string,
    true,
    end,
};

pub const ValueParseResult = struct {
    skip: usize,
    token: ?main.ValueToken,

    pub fn deinit(self: *ValueParseResult, allocator: std.mem.Allocator) void {
        if (self.token) |*token| {
            token.deinit();
        }
        _ = allocator;
    }
};

pub fn parse(allocator: std.mem.Allocator, expression: []const u8, delimiters: ?[]const u8) main.JsonError!ValueParseResult {
    var mode = Mode.scanning;
    var pos: usize = 0;
    var token: ?main.ValueToken = null;

    while (pos < expression.len and mode != .end) {
        const ch = expression[pos];

        switch (mode) {
            .scanning => {
                if (std.ascii.isWhitespace(ch)) {
                    pos += 1;
                } else if (ch == '[') {
                    mode = .array;
                } else if (ch == 'f') {
                    mode = .false;
                } else if (ch == 'n') {
                    mode = .null;
                } else if (ch == '-' or std.ascii.isDigit(ch)) {
                    mode = .number;
                } else if (ch == '{') {
                    mode = .object;
                } else if (ch == '"') {
                    mode = .string;
                } else if (ch == 't') {
                    mode = .true;
                } else if (delimiters != null and isDelimiter(ch, delimiters.?)) {
                    mode = .end;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .array => {
                const slice = expression[pos..];
                const result = try array.parse(allocator, slice);
                token = main.ValueToken{ .array = result.token };
                pos += result.skip;
                mode = .end;
            },
            .false => {
                const slice_len = @min(5, expression.len - pos);
                const slice = expression[pos .. pos + slice_len];

                if (std.mem.eql(u8, slice, "false")) {
                    token = main.ValueToken{ .false = main.FalseToken{} };
                    pos += 5;
                    mode = .end;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .null => {
                const slice_len = @min(4, expression.len - pos);
                const slice = expression[pos .. pos + slice_len];

                if (std.mem.eql(u8, slice, "null")) {
                    token = main.ValueToken{ .null = main.NullToken{} };
                    pos += 4;
                    mode = .end;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .number => {
                const slice = expression[pos..];
                const result = try number.parse(allocator, slice, delimiters);
                token = main.ValueToken{ .number = result.token };
                pos += result.skip;
                mode = .end;
            },
            .object => {
                const slice = expression[pos..];
                const result = try object.parse(allocator, slice);
                token = main.ValueToken{ .object = result.token };
                pos += result.skip;
                mode = .end;
            },
            .string => {
                const slice = expression[pos..];
                const result = try string.parse(allocator, slice);
                token = main.ValueToken{ .string = result.token };
                pos += result.skip;
                mode = .end;
            },
            .true => {
                const slice_len = @min(4, expression.len - pos);
                const slice = expression[pos .. pos + slice_len];

                if (std.mem.eql(u8, slice, "true")) {
                    token = main.ValueToken{ .true = main.TrueToken{} };
                    pos += 4;
                    mode = .end;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .end => break,
        }
    }

    if (token == null) {
        return main.JsonError.IncompleteExpression;
    }

    return ValueParseResult{
        .skip = pos,
        .token = token,
    };
}

fn isDelimiter(ch: u8, delimiters: []const u8) bool {
    for (delimiters) |delimiter| {
        if (ch == delimiter) return true;
    }
    return false;
}
