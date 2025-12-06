//Download your input.txt to this folder from https://adventofcode.com/2025/day/5
const filename = "input.txt";

const std = @import("std");
const Reader = std.Io.Reader;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const Allocator = std.mem.Allocator;
const List = std.DoublyLinkedList;
const Node = List.Node;

var file_buffer: [32768]u8 = undefined;
var buffer: [32768]u8 = undefined;
var range_buffer: [256]Range = undefined;
var foods_buffer: [1024]u64 = undefined;

const Range = struct {
    from: u64,
    to: u64,

    fn intersect(r1: Range, r2: Range) ?Range {
        if ((r1.from < r2.from and r1.to < r2.from) or (r2.from < r1.from and r2.to < r1.from)) {
            return null;
        }

        return .{ .from = @min(r1.from, r2.from), .to = @max(r1.to, r2.to) };
    }

    fn includes(r: Range, f: u64) bool {
        return f >= r.from and f <= r.to;
    }

    fn length(r: Range) u64 {
        return 1 + r.to - r.from;
    }
};

const RangeNode = struct {
    range: Range,
    node: Node,

    fn new(arena: Allocator, range: Range) !*RangeNode {
        const range_node = try arena.create(RangeNode);
        range_node.* = .{ .range = range, .node = .{} };
        return range_node;
    }
};

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile(filename, .{});
    defer input_file.close();

    var file_reader = input_file.reader(&file_buffer);
    const reader = &file_reader.interface;

    const part_1, const part_2 = try solve(reader);

    std.debug.print("Part 1: {d}\n", .{part_1});
    std.debug.print("Part 2: {d}\n", .{part_2});
}

inline fn parseInt(slice: []const u8) std.fmt.ParseIntError!u64 {
    return std.fmt.parseInt(u64, slice, 10);
}

inline fn nodeParent(node: *Node) *RangeNode {
    return @fieldParentPtr("node", node);
}

fn solve(reader: *Reader) !struct { u64, u64 } {
    var fixed_allocator: FixedBufferAllocator = .init(&buffer);

    const database = try buildDatabase(fixed_allocator.allocator(), reader);
    const food_list = try buildFoodList(reader);

    return .{ part1(database, food_list), part2(database) };
}

fn buildDatabase(arena: Allocator, reader: *Reader) ![]Range {
    var list: List = .{};

    while (reader.takeDelimiterExclusive('\n')) |line| {
        if (line.len == 0) break;
        var split = std.mem.splitScalar(u8, line, '-');
        const from = try parseInt(split.next().?);
        const to = try parseInt(split.next().?);
        const new_range: Range = .{ .from = from, .to = to };

        if (list.first == null) {
            @branchHint(.unlikely);
            const range_node: *RangeNode = try .new(arena, new_range);
            list.prepend(&range_node.node);
            continue;
        }

        var ptr: *RangeNode = nodeParent(list.first.?);
        if (new_range.from < ptr.range.from) {
            if (new_range.intersect(ptr.range)) |intersect_range| {
                ptr.range = intersect_range;
                continue;
            }
            const range_node: *RangeNode = try .new(arena, new_range);
            list.prepend(&range_node.node);
            continue;
        }

        while (true) : (ptr = nodeParent(ptr.node.next.?)) {
            const next_node = ptr.node.next orelse {
                if (new_range.intersect(ptr.range)) |intersect_range| {
                    ptr.range = intersect_range;
                } else {
                    const range_node: *RangeNode = try .new(arena, new_range);
                    list.append(&range_node.node);
                }
                break;
            };
            const next = nodeParent(next_node);

            if (new_range.intersect(ptr.range)) |int1| {
                if (int1.intersect(next.range)) |int2| {
                    list.remove(&next.node);
                    ptr.range = int2;
                    break;
                }
                ptr.range = int1;
                break;
            } else if (new_range.intersect(next.range)) |int3| {
                next.range = int3;
                break;
            }

            if (new_range.to < next.range.from) {
                const range_node: *RangeNode = try .new(arena, new_range);
                list.insertAfter(&ptr.node, &range_node.node);
                break;
            }
        }
    } else |err| {
        return err;
    }

    //now build array with ranges
    var i: usize = 0;
    var ptr: *RangeNode = nodeParent(list.first.?);

    while (true) {
        var next = nodeParent(ptr.node.next orelse {
            range_buffer[i] = ptr.range;
            i += 1;
            break;
        });

        while (ptr.range.intersect(next.range)) |intersect| {
            ptr.range = intersect;
            list.remove(&next.node);
            next = nodeParent(ptr.node.next orelse break);
        }

        range_buffer[i] = ptr.range;
        i += 1;
        ptr = nodeParent(ptr.node.next orelse break);
    }

    return range_buffer[0..i];
}

fn buildFoodList(reader: *Reader) ![]u64 {
    var i: usize = 0;

    while (reader.takeDelimiterExclusive('\n')) |line| : (i += 1) {
        foods_buffer[i] = try parseInt(line);
    } else |err| {
        switch (err) {
            error.EndOfStream => return foods_buffer[0..i],
            else => return err,
        }
    }
}

fn part1(database: []Range, foods: []u64) u64 {
    var total: u64 = 0;

    for (foods) |food| {
        if (isFresh(database, food)) total += 1;
    }

    return total;
}

fn isFresh(database: []Range, food: u64) bool {
    if (database.len == 0) return false;
    if (database.len == 1) return database[0].includes(food);

    const i = database.len / 2;
    const range = database[i];

    if (range.includes(food)) return true;
    if (food < range.from) return isFresh(database[0..i], food);
    return isFresh(database[i + 1 .. database.len], food);
}

fn part2(database: []Range) u64 {
    var total: u64 = 0;

    for (database) |range| {
        total += range.length();
    }

    return total;
}

const test_input =
    \\3-5
    \\10-14
    \\16-20
    \\12-18
    \\
    \\1
    \\5
    \\8
    \\11
    \\17
    \\32
    \\
;

test "solve" {
    var reader = Reader.fixed(test_input);
    const part_1, const part_2 = try solve(&reader);
    try std.testing.expectEqual(3, part_1);
    try std.testing.expectEqual(14, part_2);
}
