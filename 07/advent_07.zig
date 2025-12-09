//Download your input.txt to this folder from https://adventofcode.com/2025/day/7
const filename = "input.txt";

const std = @import("std");
const Reader = std.Io.Reader;
const Bitset = std.bit_set.ArrayBitSet(usize, 256);

var filebuf: [32768]u8 = undefined;
var beam_count: [256]u64 = .{0} ** 256;

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile(filename, .{});
    defer input_file.close();

    var file_reader = input_file.reader(&filebuf);
    const reader = &file_reader.interface;

    const part_1, const part_2 = solve(reader);

    std.debug.print("Part 1: {d}\n", .{part_1});
    std.debug.print("Part 2: {d}\n", .{part_2});
}

fn discardLine(reader: *Reader) void {
    _ = reader.discardDelimiterInclusive('\n') catch unreachable;
}

fn splitterFromLine(line: []const u8) Bitset {
    var splitter: Bitset = .initEmpty();
    for (line, 0..) |c, i| {
        if (c == '^') splitter.set(i);
    }
    return splitter;
}

fn solve(reader: *Reader) struct { u64, u64 } {
    var beam_hits: u64 = 0;

    const first_line = reader.takeDelimiterExclusive('\n') catch unreachable;
    discardLine(reader);
    const len = first_line.len;
    var beam: Bitset = .initEmpty();
    const start_index = std.mem.indexOfScalar(u8, first_line, 'S').?;
    beam.set(start_index);
    beam_count[start_index] = 1;

    while (reader.takeDelimiterExclusive('\n')) |line| {
        discardLine(reader);
        const splitter = splitterFromLine(line);
        const beam_hit = beam.intersectWith(splitter);
        beam_hits += @intCast(beam_hit.count());

        for (0..len) |i| {
            if (!beam_hit.isSet(i)) continue;
            beam.unset(i);
            beam.set(i - 1);
            beam.set(i + 1);

            beam_count[i - 1] += beam_count[i];
            beam_count[i + 1] += beam_count[i];
            beam_count[i] = 0;
        }
    } else |err| {
        switch (err) {
            error.EndOfStream => {
                var beamtotal: u64 = 0;
                for (0..len) |i| {
                    beamtotal += beam_count[i];
                }
                return .{ beam_hits, beamtotal };
            },
            else => unreachable,
        }
    }
}

const test_input =
    \\.......S.......
    \\...............
    \\.......^.......
    \\...............
    \\......^.^......
    \\...............
    \\.....^.^.^.....
    \\...............
    \\....^.^...^....
    \\...............
    \\...^.^...^.^...
    \\...............
    \\..^...^.....^..
    \\...............
    \\.^.^.^.^.^...^.
    \\...............
    \\
;

test "solve" {
    var reader = Reader.fixed(test_input);
    const part_1, const part_2 = solve(&reader);
    try std.testing.expectEqual(21, part_1);
    try std.testing.expectEqual(40, part_2);
}
