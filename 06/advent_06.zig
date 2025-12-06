//Download your input.txt to this folder from https://adventofcode.com/2025/day/6
const filename = "input.txt";

const std = @import("std");
const Reader = std.Io.Reader;
var file_buffer: [32768]u8 = undefined;
var number_buffer: [8192]u64 = undefined;
var part1_buffer: [8]([]u64) = undefined;
var part2_buffer: [8]([]u8) = undefined;

const Sheet = [][]u64; //just the numbers read the human way
const Table = [][]u8; //just the numbers read the porpoise way

const Op = enum {
    plus,
    mult,

    fn fromToken(token: u8) Op {
        return switch (token) {
            '+' => .plus,
            '*' => .mult,
            else => unreachable,
        };
    }

    fn op(o: Op, n1: u64, n2: u64) u64 {
        return switch (o) {
            .plus => n1 + n2,
            .mult => n1 * n2,
        };
    }
};

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile(filename, .{});
    defer input_file.close();

    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    const part_1, const part_2 = solve(reader);

    std.debug.print("Part 1: {d}\n", .{part_1});
    std.debug.print("Part 2: {d}\n", .{part_2});
}

fn solve(reader: *Reader) struct { u64, u64 } {
    const sheet, const table = readSheetTable(reader);

    return .{ part1(sheet, table), part2(table) };
}

inline fn parseInt(slice: []const u8) u64 {
    return std.fmt.parseInt(u64, slice, 10) catch unreachable;
}

fn readSheetTable(reader: *Reader) struct { Sheet, Table } {
    var i: usize = 0;
    var j: usize = 0;

    while (reader.peekDelimiterExclusive('\n')) |line| : (i += 1) {
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        const peekd_token = tokens.peek().?;
        part2_buffer[i] = line;
        if (!std.ascii.isDigit(peekd_token[0])) break;
        reader.toss(line.len + 1);

        const start = j;
        while (tokens.next()) |number| : (j += 1) {
            number_buffer[j] = parseInt(number);
        }
        part1_buffer[i] = number_buffer[start..j];
    } else |_| unreachable;

    return .{ part1_buffer[0..i], part2_buffer[0 .. i + 1] };
}

fn part1(sheet: Sheet, table: Table) u64 {
    var total: u64 = 0;
    var i: usize = 0;
    const height = sheet.len;

    const line = table[table.len - 1];
    var tokens = std.mem.tokenizeScalar(u8, line, ' ');
    while (tokens.next()) |t| : (i += 1) {
        var problem: u64 = sheet[0][i];
        const o = Op.fromToken(t[0]);
        for (1..height) |j| {
            problem = o.op(problem, sheet[j][i]);
        }
        total += problem;
    }

    return total;
}

fn part2(table: Table) u64 {
    var total: u64 = 0;
    var i: usize = table[0].len - 1;
    var j: usize = 0;
    const height = table.len;
    var numbers: [8]u64 = undefined;

    while (i < table[0].len) : (i -%= 1) {
        var number: u64 = 0;
        for (0..height - 1) |k| {
            const c = table[k][i];
            if (c == ' ') continue;
            const n: u64 = c - '0';
            number = 10 * number + n;
        }
        numbers[j] = number;
        j += 1;
        const op_char = table[height - 1][i];
        if (op_char == ' ') continue;

        const o = Op.fromToken(op_char);
        number = numbers[0];

        for (1..j) |k| {
            number = o.op(number, numbers[k]);
        }

        total += number;
        j = 0;
        i -%= 1;
    }

    return total;
}

const test_input =
    \\123 328  51 64 
    \\ 45 64  387 23 
    \\  6 98  215 314
    \\*   +   *   +  
    \\
;

test "solve" {
    var reader = Reader.fixed(test_input);
    const part_1, const part_2 = solve(&reader);
    try std.testing.expectEqual(4277556, part_1);
    try std.testing.expectEqual(3263827, part_2);
}
