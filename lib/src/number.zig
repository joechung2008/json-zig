const std = @import("std");
const main = @import("main.zig");

const Mode = enum {
    scanning,
    characteristic,
    characteristic_digit,
    decimal_point,
    mantissa,
    exponent,
    exponent_sign,
    exponent_first_digit,
    exponent_digits,
    end,
};

pub const NumberParseResult = struct {
    skip: usize,
    token: main.NumberToken,
};

pub fn parse(allocator: std.mem.Allocator, expression: []const u8, delimiters: ?[]const u8) main.JsonError!NumberParseResult {
    const default_delimiters = " \n\r\t";
    const delimiter_set = delimiters orelse default_delimiters;
    var mode = Mode.scanning;
    var pos: usize = 0;
    var value_string = std.ArrayList(u8){};
    defer value_string.deinit(allocator);

    var token = main.NumberToken{
        .value = null,
    };

    while (pos < expression.len and mode != .end) {
        const ch = expression[pos];

        switch (mode) {
            .scanning => {
                if (std.ascii.isWhitespace(ch)) {
                    pos += 1;
                } else if (ch == '-') {
                    try value_string.append(allocator, '-');
                    pos += 1;
                    mode = .characteristic;
                } else {
                    mode = .characteristic;
                }
            },
            .characteristic => {
                if (ch == '0') {
                    try value_string.append(allocator, '0');
                    pos += 1;
                    mode = .decimal_point;
                } else if (ch >= '1' and ch <= '9') {
                    try value_string.append(allocator, ch);
                    pos += 1;
                    mode = .characteristic_digit;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .characteristic_digit => {
                if (std.ascii.isDigit(ch)) {
                    try value_string.append(allocator, ch);
                    pos += 1;
                } else if (isDelimiter(ch, delimiter_set)) {
                    mode = .end;
                } else {
                    mode = .decimal_point;
                }
            },
            .decimal_point => {
                if (ch == '.') {
                    try value_string.append(allocator, '.');
                    pos += 1;
                    mode = .mantissa;
                } else if (isDelimiter(ch, delimiter_set)) {
                    mode = .end;
                } else {
                    mode = .exponent;
                }
            },
            .mantissa => {
                if (std.ascii.isDigit(ch)) {
                    try value_string.append(allocator, ch);
                    pos += 1;
                } else if (ch == 'e' or ch == 'E') {
                    mode = .exponent;
                } else if (isDelimiter(ch, delimiter_set)) {
                    mode = .end;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .exponent => {
                if (ch == 'e' or ch == 'E') {
                    try value_string.append(allocator, 'e');
                    pos += 1;
                    mode = .exponent_sign;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .exponent_sign => {
                if (ch == '+' or ch == '-') {
                    try value_string.append(allocator, ch);
                    pos += 1;
                    mode = .exponent_first_digit;
                } else {
                    mode = .exponent_first_digit;
                }
            },
            .exponent_first_digit => {
                if (std.ascii.isDigit(ch)) {
                    try value_string.append(allocator, ch);
                    pos += 1;
                    mode = .exponent_digits;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .exponent_digits => {
                if (std.ascii.isDigit(ch)) {
                    try value_string.append(allocator, ch);
                    pos += 1;
                } else if (isDelimiter(ch, delimiter_set)) {
                    mode = .end;
                } else {
                    return main.JsonError.UnexpectedCharacter;
                }
            },
            .end => break,
        }
    }

    switch (mode) {
        .characteristic, .exponent_first_digit, .exponent_sign => {
            return main.JsonError.IncompleteExpression;
        },
        else => {
            token.value = std.fmt.parseFloat(f64, value_string.items) catch {
                return main.JsonError.UnexpectedCharacter;
            };
        },
    }

    return NumberParseResult{
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
