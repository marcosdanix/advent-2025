//Download your input.txt to this folder from https://adventofcode.com/2025/day/8
const filename = "input.txt";

const std = @import("std");
const Reader = std.Io.Reader;
const Order = std.math.Order;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const EdgeLenHeap = std.PriorityQueue(Edge, void, compareEdgeLenFn);
const NetworkHeap = std.PriorityQueue(usize, void, compareNetworkFn);
const Boxset = std.bit_set.ArrayBitSet(usize, 1024);

var filebuf: [32768]u8 = undefined;
var edgelenbuf: [16777216]u8 = undefined;
var boxes: [1024]Box = undefined;
var networks: [1024]Boxset = undefined;

const Box = struct {
    x: i64,
    y: i64,
    z: i64,
    n: usize,

    fn quadranceTo(a: Box, b: Box) i64 {
        return square(b.x - a.x) + square(b.y - a.y) + square(b.z - a.z);
    }
};

inline fn square(x: i64) i64 {
    return std.math.powi(i64, x, 2) catch unreachable;
}

const Edge = packed struct {
    quad_len: i64,
    index_from: u32,
    index_to: u32,

    fn init(from: usize, to: usize) Edge {
        return .{
            .quad_len = boxes[from].quadranceTo(boxes[to]),
            .index_from = @truncate(from),
            .index_to = @truncate(to),
        };
    }

    fn compare(a: Edge, b: Edge) Order {
        return std.math.order(a.quad_len, b.quad_len);
    }
};

fn compareEdgeLenFn(context: void, a: Edge, b: Edge) Order {
    _ = context;
    return a.compare(b);
}

fn compareNetworkFn(context: void, a: usize, b: usize) Order {
    _ = context;
    return std.math.order(networks[a].count(), networks[b].count()).invert();
}

inline fn parseInt(slice: []const u8) i64 {
    return std.fmt.parseInt(i64, slice, 10) catch unreachable;
}

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile(filename, .{});
    defer input_file.close();

    var file_reader = input_file.reader(&filebuf);
    const reader = &file_reader.interface;

    // const part_1, const part_2 = try solve(reader);
    const part_1, const part_2 = try solve(reader, 1000);

    std.debug.print("Part 1: {d}\n", .{part_1});
    std.debug.print("Part 2: {d}\n", .{part_2});
}

fn solve(reader: *Reader, times: usize) !struct { i64, i64 } {
    var fixed_allocator: FixedBufferAllocator = .init(&edgelenbuf);
    var edgelen_heap: EdgeLenHeap = .init(fixed_allocator.allocator(), {});
    var i: usize = 0; //counts the number of networks
    var part_1: i64 = 0;
    var part_2: i64 = 0;

    //Classic Kruskal's algorithm - first step is to sort the edges by weight
    while (reader.takeDelimiterExclusive('\n')) |line| : (i += 1) {
        var positions = std.mem.splitScalar(u8, line, ',');
        boxes[i] = .{
            .x = parseInt(positions.next().?),
            .y = parseInt(positions.next().?),
            .z = parseInt(positions.next().?),
            .n = i,
        };
        networks[i] = .initEmpty();
        networks[i].set(i);

        for (0..i) |j| {
            const edge: Edge = .init(i, j);
            edgelen_heap.add(edge) catch unreachable;
        }
    } else |err| {
        if (err != error.EndOfStream) return err;
    }

    const network_length = i;

    //then create networks from the edge weights
    //in this case we will run this algorithm a certain number of times
    var n: usize = 0;
    while (i > 1) : (n += 1) {
        const edge = edgelen_heap.remove();
        const box_from = boxes[edge.index_from];
        const box_to = boxes[edge.index_to];

        if (box_from.n != box_to.n) {
            i -= 1;
            //join them in the network, pick the smallest n
            const new_n, const old_n =
                if (box_from.n < box_to.n)
                    .{ box_from.n, box_to.n } //
                else
                    .{ box_to.n, box_from.n }; //

            var it = networks[old_n].iterator(.{});
            while (it.next()) |box_i| {
                boxes[box_i].n = new_n;
                networks[new_n].set(box_i);
                networks[old_n].unset(box_i);
            }
        }

        if (n + 1 == times) {
            part_1 = part1(fixed_allocator.allocator(), network_length);
        }

        if (i == 1) {
            part_2 = boxes[edge.index_from].x * boxes[edge.index_to].x;
        }
    }

    return .{ part_1, part_2 };
}

fn part1(gpa: std.mem.Allocator, len: usize) i64 {
    var network_heap: NetworkHeap = .init(gpa, {});
    defer network_heap.deinit();

    //let's find the three highest networks
    for (0..len) |n| {
        network_heap.add(n) catch unreachable; //the magic is in the compare function
    }

    return @intCast(networks[network_heap.remove()].count() //
    * networks[network_heap.remove()].count() //
    * networks[network_heap.remove()].count());
}

const test_input =
    \\162,817,812
    \\57,618,57
    \\906,360,560
    \\592,479,940
    \\352,342,300
    \\466,668,158
    \\542,29,236
    \\431,825,988
    \\739,650,466
    \\52,470,668
    \\216,146,977
    \\819,987,18
    \\117,168,530
    \\805,96,715
    \\346,949,466
    \\970,615,88
    \\941,993,340
    \\862,61,35
    \\984,92,344
    \\425,690,689
;

test "solve" {
    var reader = Reader.fixed(test_input);
    const part_1, const part_2 = try solve(&reader, 10);
    try std.testing.expectEqual(40, part_1);
    try std.testing.expectEqual(25272, part_2);
}
