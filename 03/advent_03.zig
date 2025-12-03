//Download your input.txt to this folder from https://adventofcode.com/2025/day/3
const filename = "input.txt";

const std = @import("std");
const Reader = std.Io.Reader;
var buffer: [32768]u8 = undefined;

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile(filename, .{});
    defer input_file.close();

    var file_reader = input_file.reader(&buffer);
    const reader = &file_reader.interface;

    const part_1, const part_2 = try solve(reader);

    std.debug.print("Part 1: {d}\n", .{part_1});
    std.debug.print("Part 2: {d}\n", .{part_2});
}

inline fn digit(c: u8) u8 {
    return c - '0';
}

fn solve(reader: *Reader) !struct { u64, u64 } {
    var total_1: u64 = 0;
    var total_2: u64 = 0;

    while (reader.takeDelimiterExclusive('\n')) |bank| {
        total_1 += part1(bank);
        total_2 += part2(bank);
    } else |err| {
        switch (err) {
            error.EndOfStream => return .{ total_1, total_2 },
            else => return err,
        }
    }
}

fn part1(bank: []const u8) u64 {
    var high_tens_digit: u64 = 0;
    var high_tens_idx: usize = 0;

    for (bank[0 .. bank.len - 1], 0..) |c, i| {
        const d = digit(c);
        if (d > high_tens_digit) {
            high_tens_digit = d;
            high_tens_idx = i;
        }
        if (d == 9) break;
    }

    var high_ones_digit: u64 = 0;
    var high_ones_idx: usize = high_tens_idx + 1;

    for (bank[high_tens_idx + 1 .. bank.len], high_tens_idx + 1..) |c, i| {
        const d = digit(c);
        if (d > high_ones_digit) {
            high_ones_digit = d;
            high_ones_idx = i;
        }
        if (d == 9) break;
    }

    return high_tens_digit * 10 + high_ones_digit;
}

fn part2(bank: []const u8) u64 {
    var high_digit: [12]u8 = .{0} ** 12;
    var high_pos: [12]u8 = .{0} ** 12;
    var number: u64 = 0;

    for (0..12) |n| {
        const x: usize = 12 - n - 1;
        number *= 10;

        for (bank[high_pos[n] .. bank.len - x], high_pos[n]..) |c, i| {
            const d = digit(c);
            if (d > high_digit[n]) {
                high_digit[n] = d;
                high_pos[n] = @truncate(i);
            }
            if (d == 9) break;
        }

        if (n + 1 < 12) high_pos[n + 1] = 1 + high_pos[n];
        number += high_digit[n];
    }

    return number;
}

const test_input =
    \\987654321111111
    \\811111111111119
    \\234234234234278
    \\818181911112111
    \\
;

test "solve" {
    var reader = Reader.fixed(test_input);
    const part_1, const part_2 = try solve(&reader);
    try std.testing.expectEqual(357, part_1);
    try std.testing.expectEqual(3121910778619, part_2);
}
