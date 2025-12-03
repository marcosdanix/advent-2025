//Download your input.txt to this folder from https://adventofcode.com/2025/day/2
const filename = "input.txt";

const std = @import("std");
const Reader = std.Io.Reader;
var buffer: [512]u8 = undefined;
var number: [64]u8 = undefined;

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile(filename, .{});
    defer input_file.close();

    var file_reader = input_file.reader(&buffer);
    const reader = &file_reader.interface;

    const part_1, const part_2 = try solve(reader);

    std.debug.print("Part 1: {d}\n", .{part_1});
    std.debug.print("Part 2: {d}\n", .{part_2});
}

inline fn printInt(slice: []u8, value: u64) usize {
    return std.fmt.printInt(slice, value, 10, .lower, .{});
}

inline fn parseInt(slice: []const u8) std.fmt.ParseIntError!u64 {
    return std.fmt.parseInt(u64, slice, 10);
}

fn solve(reader: *Reader) !struct { u64, u64 } {
    var total_1: u64 = 0;
    var total_2: u64 = 0;

    while (reader.takeDelimiterExclusive(',')) |range| {
        var split = std.mem.splitAny(u8, range, "-\n");
        const id1 = try parseInt(split.next().?);
        const id2 = try parseInt(split.next().?);

        total_1 += try part1(id1, id2);
        total_2 += try part2(id1, id2);
    } else |err| {
        switch (err) {
            error.EndOfStream => return .{ total_1, total_2 },
            else => return err,
        }
    }
}

fn part1(id1: u64, id2: u64) !u64 {
    var total: u64 = 0;
    var i = id1;
    var first_half: u64 = undefined;

    //let's get the first invalid ID that is greater or equal to i.
    var size = printInt(&number, i);

    //an invalid ID must have an even number of digits
    if (size % 2 != 0) {
        //this number will have size+1 digits, thus even size
        i = try std.math.powi(u64, 10, size);
        size = printInt(&number, i);
        std.debug.assert(size % 2 == 0);
        first_half = try parseInt(number[0 .. size / 2]);
        i += first_half;
    } else if (!std.mem.eql(u8, number[0 .. size / 2], number[size / 2 .. size])) {
        first_half = try parseInt(number[0 .. size / 2]);
        const second_half = try parseInt(number[size / 2 .. size]);
        if (second_half < first_half) {
            @memcpy(number[size / 2 .. size], number[0 .. size / 2]);
            i = try parseInt(number[0..size]);
        } else {
            first_half += 1;
            size = printInt(&number, first_half);
            size *= 2;
            @memcpy(number[size / 2 .. size], number[0 .. size / 2]);
            i = try parseInt(number[0..size]);
        }
    } else {
        first_half = try parseInt(number[0 .. size / 2]);
    }

    //Now i is an invalid id
    while (i <= id2) {
        total += i;
        first_half += 1;
        size = printInt(&number, first_half);
        size *= 2;
        @memcpy(number[size / 2 .. size], number[0 .. size / 2]);
        i = try parseInt(number[0..size]);
    }

    return total;
}

fn part2(id1: u64, id2: u64) !u64 {
    var total: u64 = 0;
    for (id1..id2 + 1) |i| {
        const size = printInt(&number, i);
        if (size == 1) continue;
        for (1..1 + size / 2) |n| {
            if (size % n != 0) continue;
            const m = size / n;
            //There are m groupings of length n in a number with size digits
            const grouping = number[0..n];
            for (1..m) |j| {
                if (!std.mem.eql(u8, grouping, number[j * n .. (j + 1) * n])) {
                    break;
                }
            } else {
                total += i;
                break; // don't double add the same invalid ID
            }
        }
    }

    return total;
}

const test_input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224," //
    ++ "1698522-1698528,446443-446449,38593856-38593862,565653-565659," //
    ++ "824824821-824824827,2121212118-2121212124"; //

test "solve" {
    var reader = Reader.fixed(test_input);
    const part_1, const part_2 = try solve(&reader);
    try std.testing.expectEqual(1227775554, part_1);
    try std.testing.expectEqual(4174379265, part_2);
}
