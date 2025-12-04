//Download your input.txt to this folder from https://adventofcode.com/2025/day/4
const filename = "input.txt";

const std = @import("std");
const Reader = std.Io.Reader;
var buffer: [32768]u8 = undefined;
var lines: [256]([]u8) = undefined;

const Map = [][]u8;

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile(filename, .{});
    defer input_file.close();

    var file_reader = input_file.reader(&buffer);
    const reader = &file_reader.interface;

    const map = readMap(reader);

    const part_1 = part1(map);
    const part_2 = part2(map);

    std.debug.print("Part 1: {d}\n", .{part_1});
    std.debug.print("Part 2: {d}\n", .{part_2});
}

fn readMap(reader: *Reader) Map {
    var i: usize = 0;

    while (reader.takeDelimiterExclusive('\n')) |line| {
        lines[i] = line;
        i += 1;
    } else |err| {
        switch (err) {
            error.EndOfStream => return lines[0..i],
            else => unreachable,
        }
    }
}

fn numRolls(map: Map, line: i64, row: i64) u8 {
    if (line < 0 or line >= map.len) return 0;
    const l: usize = @intCast(line);
    const r_0: usize = @intCast(@max(row - 1, 0));
    const r_2: usize = @intCast(@min(row + 2, map[l].len));
    var count: u8 = 0;
    for (r_0..r_2) |r| {
        if (isRoll(map[l][r])) count += 1;
    }
    return count;
}

fn part1(map: Map) u64 {
    var total: u64 = 0;

    for (map, 0..) |map_line, l| {
        const line: i64 = @intCast(l);
        for (0..map_line.len) |r| {
            if (isEmpty(map_line[r])) continue;
            const row: i64 = @intCast(r);
            const neighbors = numRolls(map, line - 1, row) //
                + numRolls(map, line, row) - 1 //
                + numRolls(map, line + 1, row);
            if (neighbors < 4) total += 1;
        }
    }

    return total;
}

inline fn isRoll(char: u8) bool {
    return char == '@' or char >= 0 and char <= 9;
}

inline fn isEmpty(char: u8) bool {
    return char == '.';
}

inline fn isMarked(char: u8) bool {
    return char & 0x80 != 0;
}

fn removeNeighbor(map: Map, line: i64, row: i64, this_line: bool) void {
    if (line < 0 or line >= map.len) return;
    const l: usize = @intCast(line);
    const r_0: usize = @intCast(@max(row - 1, 0));
    const r_2: usize = @intCast(@min(row + 2, map[l].len));
    for (r_0..r_2) |r| {
        if (this_line and r == row) map[l][r] = '.' //
        else if (!isEmpty(map[l][r])) map[l][r] -= 1;
    }
}

fn part2(map: Map) u64 {

    //convert the map of paper rolls, to a map of convolutions
    //or number of neighbors
    //and keep editing the convolution map
    for (map, 0..) |map_line, l| {
        const line: i64 = @intCast(l);
        for (0..map_line.len) |r| {
            if (isEmpty(map_line[r])) continue;
            const row: i64 = @intCast(r);
            const neighbors = numRolls(map, line - 1, row) //
                + numRolls(map, line, row) - 1 //
                + numRolls(map, line + 1, row);
            map[l][r] = neighbors;
        }
    }

    var total: u64 = 0;
    var removed: u64 = undefined;

    return while (true) : (total += removed) {
        removed = 0;

        //this has to be solved in two passes
        //the first pass marks the rolls that will be removed
        //the second pass actually recalculates the number of neighbors

        //if the MSBit is one, then it's marked for removal
        for (map, 0..) |map_line, l| {
            for (map_line, 0..) |neighbors, r| {
                if (isEmpty(neighbors) or neighbors >= 4) continue;
                removed += 1;
                map[l][r] |= 0x80;
            }
        }

        //uncomment the printing lines to visualize the rolls being gathered
        for (map, 0..) |map_line, l| {
            const line: i64 = @intCast(l);
            for (map_line, 0..) |neighbors, r| {
                if (!isMarked(neighbors)) {
                    // printNotRemoved(neighbors);
                    continue;
                }
                const row: i64 = @intCast(r);
                removeNeighbor(map, line - 1, row, false);
                removeNeighbor(map, line, row, true);
                removeNeighbor(map, line + 1, row, false);
                // printRemoved();
            }
            // std.debug.print("\n", .{});
        }

        // std.debug.print("\nRemoved {d}\n\n", .{removed});
        if (removed == 0) break total;
    };
}

inline fn printNotRemoved(char: u8) void {
    if (isRoll(char)) std.debug.print("@", .{}) else std.debug.print(".", .{});
}

inline fn printRemoved() void {
    std.debug.print("x", .{});
}

const test_input =
    \\..@@.@@@@.
    \\@@@.@.@.@@
    \\@@@@@.@.@@
    \\@.@@@@..@.
    \\@@.@@@@.@@
    \\.@@@@@@@.@
    \\.@.@.@.@@@
    \\@.@@@.@@@@
    \\.@@@@@@@@.
    \\@.@.@@@.@.
    \\
;

test "solve" {
    var reader = Reader.fixed(test_input);
    const map = readMap(&reader);
    try std.testing.expectEqual(13, part1(map));
    try std.testing.expectEqual(43, part2(map));
}
