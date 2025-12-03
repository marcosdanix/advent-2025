//Download your input.txt to this folder from https://adventofcode.com/2025/day/1
const filename = "input.txt";

const std = @import("std");
const Reader = std.Io.Reader;

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile(filename, .{});
    defer input_file.close();

    var buffer: [8]u8 = undefined;
    var file_reader = input_file.reader(&buffer);
    const reader = &file_reader.interface;

    const part_1, const part_2 = try solve(reader);

    std.debug.print("Part 1: {d}\n", .{part_1});
    std.debug.print("Part 2: {d}\n", .{part_2});
}

const Side = enum {
    L,
    R,

    fn init(char: u8) Side {
        return switch (char) {
            'L' => .L,
            'R' => .R,
            else => unreachable,
        };
    }
};

fn solve(reader: *Reader) !struct { i64, i64 } {
    var lock: i64 = 50;
    var part_1: i64 = 0;
    var part_2: i64 = 0;

    while (reader.takeDelimiterExclusive('\n')) |instruction| {
        const side: Side = .init(instruction[0]);
        const amount = try std.fmt.parseInt(i64, instruction[1..], 10);
        std.debug.assert(amount > 0);
        const prev_lock = lock;

        switch (side) {
            .L => lock = @mod(lock - amount, 100),
            .R => lock = @mod(lock + amount, 100),
        }

        if (lock == 0) {
            part_1 += 1;
        }

        part_2 += @divFloor(amount, 100);

        const remaining = @mod(amount, 100);
        std.debug.assert(remaining > 0);
        if (prev_lock != 0) {
            switch (side) {
                .L => if (prev_lock - remaining <= 0) {
                    part_2 += 1;
                },
                .R => if (prev_lock + remaining >= 100) {
                    part_2 += 1;
                },
            }
        }

        // Uncomment the line below to see how the lock and the solution changes
        // std.debug.print("{d} -> {s} -> {d}: P1:{d} P2:{d}\n", .{ prev_lock, instruction, lock, part_1, part_2 });
    } else |err| {
        switch (err) {
            error.EndOfStream => return .{ part_1, part_2 },
            else => return err,
        }
    }
}

const test_input =
    \\L68
    \\L30
    \\R48
    \\L5
    \\R60
    \\L55
    \\L1
    \\L99
    \\R14
    \\L82
;

test "solve" {
    var reader = Reader.fixed(test_input);
    const part_1, const part_2 = try solve(&reader);
    try std.testing.expectEqual(3, part_1);
    try std.testing.expectEqual(6, part_2);
}
