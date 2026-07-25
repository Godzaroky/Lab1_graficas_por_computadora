const std = @import("std");
const Io = std.Io;
const poly = @import("polygon_fill.zig");

const Lab1_graficas_por_computadora = @import("Lab1_graficas_por_computadora");

// --- Canvas para rellenar los polígonos ---
const CANVAS_WIDTH: usize = 800;
const CANVAS_HEIGHT: usize = 450;

// Buffer global RGB (3 bytes por pixel). Se usa global porque setPixel
// necesita ser un puntero a función sin contexto capturado.
var canvas: [CANVAS_HEIGHT][CANVAS_WIDTH][3]u8 = undefined;

fn clearCanvas() void {
    for (&canvas) |*row| {
        for (row) |*px| {
            px.* = .{ 0, 0, 0 }; // negro
        }
    }
}

fn setPixelWhite(x: i32, y: i32) void {
    if (x < 0 or y < 0) return;
    const ux: usize = @intCast(x);
    const uy: usize = @intCast(y);
    if (ux >= CANVAS_WIDTH or uy >= CANVAS_HEIGHT) return;
    canvas[uy][ux] = .{ 255, 255, 255 }; // blanco
}

fn fillAllPolygons(allocator: std.mem.Allocator) !void {
    const polygono1 = [_]poly.Point{
        .{ .x = 165, .y = 380 }, .{ .x = 185, .y = 360 }, .{ .x = 180, .y = 330 },
        .{ .x = 207, .y = 345 }, .{ .x = 233, .y = 330 }, .{ .x = 230, .y = 360 },
        .{ .x = 250, .y = 380 }, .{ .x = 220, .y = 385 }, .{ .x = 205, .y = 410 },
        .{ .x = 193, .y = 383 },
    };

    const polygono2 = [_]poly.Point{
        .{ .x = 321, .y = 335 }, .{ .x = 288, .y = 286 },
        .{ .x = 339, .y = 251 }, .{ .x = 374, .y = 302 },
    };

    const polygono3 = [_]poly.Point{
        .{ .x = 377, .y = 249 }, .{ .x = 411, .y = 197 }, .{ .x = 436, .y = 249 },
    };

    // Incluye el "puente" hacia el agujero interior
    const polygono4 = [_]poly.Point{
        .{ .x = 413, .y = 177 }, .{ .x = 448, .y = 159 }, .{ .x = 502, .y = 88 },
        .{ .x = 553, .y = 53 },  .{ .x = 535, .y = 36 },  .{ .x = 676, .y = 37 },
        .{ .x = 660, .y = 52 },  .{ .x = 750, .y = 145 }, .{ .x = 761, .y = 179 },
        .{ .x = 672, .y = 192 }, .{ .x = 659, .y = 214 }, .{ .x = 615, .y = 214 },
        .{ .x = 632, .y = 230 }, .{ .x = 580, .y = 230 }, .{ .x = 597, .y = 215 },
        .{ .x = 552, .y = 214 }, .{ .x = 517, .y = 144 }, .{ .x = 466, .y = 180 },
    };

    const polygono5 = [_]poly.Point{
        .{ .x = 682, .y = 175 }, .{ .x = 708, .y = 120 },
        .{ .x = 735, .y = 148 }, .{ .x = 739, .y = 170 },
    };

    const all_polygons = [_][]const poly.Point{
        &polygono1, &polygono2, &polygono3, &polygono4, &polygono5,
    };

    try poly.fillPolygons(allocator, &all_polygons, setPixelWhite);
}

pub fn main(init: std.process.Init) !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    // --- Relleno de polígonos ---
    clearCanvas();
    try fillAllPolygons(arena);
    std.log.info("Imagen generada en output.ppm", .{});

    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try Lab1_graficas_por_computadora.printAnotherMessage(stdout_writer);

    try stdout_writer.flush();
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa);
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    try std.testing.fuzz({}, testOne, .{});
}

fn testOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;
    const gpa = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(gpa);
    while (!smith.eos()) switch (smith.value(enum { add_data, dup_data })) {
        .add_data => {
            const slice = try list.addManyAsSlice(gpa, smith.value(u4));
            smith.bytes(slice);
        },
        .dup_data => {
            if (list.items.len == 0) continue;
            if (list.items.len > std.math.maxInt(u32)) return error.SkipZigTest;
            const len = smith.valueRangeAtMost(u32, 1, @min(32, list.items.len));
            const off = smith.valueRangeAtMost(u32, 0, @intCast(list.items.len - len));
            try list.appendSlice(gpa, list.items[off..][0..len]);
            try std.testing.expectEqualSlices(
                u8,
                list.items[off..][0..len],
                list.items[list.items.len - len ..],
            );
        },
    };
}
