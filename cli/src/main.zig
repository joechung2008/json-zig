const std = @import("std");
const builtin = @import("builtin");
const shared = @import("shared");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Read all input from stdin
    var input_buffer: [1024 * 1024]u8 = undefined;
    const stdin_handle = if (builtin.os.tag == .windows)
        try std.os.windows.GetStdHandle(std.os.windows.STD_INPUT_HANDLE)
    else
        std.posix.STDIN_FILENO;
    const stdin = std.fs.File{ .handle = stdin_handle };
    const bytes_read = try stdin.readAll(&input_buffer);
    const input = try allocator.dupe(u8, input_buffer[0..bytes_read]);
    defer allocator.free(input);

    // Trim whitespace from input
    const json_string = std.mem.trim(u8, input, " \n\r\t");

    if (json_string.len == 0) {
        std.debug.print("Error: No input provided\n", .{});
        std.process.exit(1);
    }

    // Parse the JSON
    var result = shared.parse(allocator, json_string) catch |err| {
        std.debug.print("JSON Parse Error: {}\n", .{err});
        std.process.exit(1);
    };
    defer result.deinit(allocator);

    // Display the parsed result
    if (result.token) |token| {
        std.debug.print("Successfully parsed JSON:\n", .{});
        printToken(token, 0);
    } else {
        std.debug.print("Error: No token parsed\n", .{});
        std.process.exit(1);
    }
}

fn printToken(token: shared.ValueToken, indent: usize) void {
    const indent_str = "  " ** 10; // Pre-allocate enough spaces
    const current_indent = indent_str[0 .. indent * 2];

    switch (token) {
        .number => |num| {
            if (num.value) |value| {
                std.debug.print("{s}Number: {d}\n", .{ current_indent, value });
            }
        },
        .string => |str| {
            if (str.value) |value| {
                std.debug.print("{s}String: \"{s}\"\n", .{ current_indent, value });
            }
        },
        .true => std.debug.print("{s}Boolean: true\n", .{current_indent}),
        .false => std.debug.print("{s}Boolean: false\n", .{current_indent}),
        .null => std.debug.print("{s}Null\n", .{current_indent}),
        .array => |arr| {
            std.debug.print("{s}Array ({} elements):\n", .{ current_indent, arr.values.items.len });
            for (arr.values.items, 0..) |item, i| {
                std.debug.print("{s}  [{}]:\n", .{ current_indent, i });
                printToken(item, indent + 2);
            }
        },
        .object => |obj| {
            std.debug.print("{s}Object ({} members):\n", .{ current_indent, obj.members.items.len });
            for (obj.members.items) |member| {
                if (member.key) |key| {
                    if (key.value) |key_value| {
                        std.debug.print("{s}  \"{s}\":\n", .{ current_indent, key_value });
                        if (member.value) |value| {
                            printToken(value, indent + 2);
                        }
                    }
                }
            }
        },
    }
}
