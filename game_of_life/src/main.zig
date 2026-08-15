const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

// -----------------------------------------------------------------------
// Configuracion general
// -----------------------------------------------------------------------

const FB_W: i32 = 140;
const FB_H: i32 = 90;
const CELL_SIZE: i32 = 8;

const SCREEN_W: i32 = FB_W * CELL_SIZE;
const SCREEN_H: i32 = FB_H * CELL_SIZE;

const FB_LEN: usize = @intCast(FB_W * FB_H);

const DEAD: rl.Color = rl.BLACK;
const ALIVE_DEFAULT: rl.Color = rl.RAYWHITE;

const NUM_THREADS: usize = 4;
const THREAD_COLORS = [NUM_THREADS]rl.Color{ rl.SKYBLUE, rl.LIME, rl.GOLD, rl.VIOLET };

const Framebuffer = struct {
    cells: [FB_LEN]rl.Color = [_]rl.Color{DEAD} ** FB_LEN,

    fn idx(x: i32, y: i32) ?usize {
        if (x < 0 or y < 0 or x >= FB_W or y >= FB_H) return null;
        return @intCast(y * FB_W + x);
    }
};

fn point(fb: *Framebuffer, x: i32, y: i32, color: rl.Color) void {
    const i = Framebuffer.idx(x, y) orelse return;
    fb.cells[i] = color;
}

fn get_color(fb: *const Framebuffer, x: i32, y: i32) rl.Color {
    const i = Framebuffer.idx(x, y) orelse return DEAD;
    return fb.cells[i];
}

fn isAlive(color: rl.Color) bool {
    return !(color.r == DEAD.r and color.g == DEAD.g and color.b == DEAD.b);
}

// -----------------------------------------------------------------------
// Algoritmo de Conway
// -----------------------------------------------------------------------

fn countNeighbors(fb: *const Framebuffer, x: i32, y: i32) u8 {
    var count: u8 = 0;
    var dy: i32 = -1;
    while (dy <= 1) : (dy += 1) {
        var dx: i32 = -1;
        while (dx <= 1) : (dx += 1) {
            if (dx == 0 and dy == 0) continue;
            const nx = @mod(x + dx, FB_W);
            const ny = @mod(y + dy, FB_H);
            if (isAlive(get_color(fb, nx, ny))) count += 1;
        }
    }
    return count;
}

fn stepBand(current: *const Framebuffer, next: *Framebuffer, y_start: i32, y_end: i32, birth_color: rl.Color) void {
    var y = y_start;
    while (y < y_end) : (y += 1) {
        var x: i32 = 0;
        while (x < FB_W) : (x += 1) {
            const alive = isAlive(get_color(current, x, y));
            const n = countNeighbors(current, x, y);
            const survives = alive and (n == 2 or n == 3);
            const borns = !alive and (n == 3);
            if (survives or borns) {
                point(next, x, y, birth_color);
            } else {
                point(next, x, y, DEAD);
            }
        }
    }
}

const ThreadArgs = struct {
    current: *const Framebuffer,
    next: *Framebuffer,
    y_start: i32,
    y_end: i32,
    color: rl.Color,
};

fn threadWorker(args: ThreadArgs) void {
    stepBand(args.current, args.next, args.y_start, args.y_end, args.color);
}

fn nextGeneration(current: *const Framebuffer, next: *Framebuffer) void {
    var threads: [NUM_THREADS]std.Thread = undefined;
    const band: i32 = @divTrunc(FB_H, @as(i32, @intCast(NUM_THREADS)));

    var i: usize = 0;
    while (i < NUM_THREADS) : (i += 1) {
        const y_start: i32 = @as(i32, @intCast(i)) * band;
        const y_end: i32 = if (i == NUM_THREADS - 1) FB_H else y_start + band;
        const args = ThreadArgs{
            .current = current,
            .next = next,
            .y_start = y_start,
            .y_end = y_end,
            .color = THREAD_COLORS[i],
        };
        threads[i] = std.Thread.spawn(.{}, threadWorker, .{args}) catch unreachable;
    }
    i = 0;
    while (i < NUM_THREADS) : (i += 1) {
        threads[i].join();
    }
}

fn spawn(fb: *Framebuffer, ox: i32, oy: i32, offsets: []const [2]i32, color: rl.Color) void {
    for (offsets) |o| {
        point(fb, ox + o[0], oy + o[1], color);
    }
}

// --- Formas estables ---
fn spawnBlock(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{ .{ 0, 0 }, .{ 1, 0 }, .{ 0, 1 }, .{ 1, 1 } }, ALIVE_DEFAULT);
}
fn spawnBeehive(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{ .{ 1, 0 }, .{ 2, 0 }, .{ 0, 1 }, .{ 3, 1 }, .{ 1, 2 }, .{ 2, 2 } }, ALIVE_DEFAULT);
}
fn spawnLoaf(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{ .{ 1, 0 }, .{ 2, 0 }, .{ 0, 1 }, .{ 3, 1 }, .{ 1, 2 }, .{ 3, 2 }, .{ 2, 3 } }, ALIVE_DEFAULT);
}
fn spawnBoat(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{ .{ 0, 0 }, .{ 1, 0 }, .{ 0, 1 }, .{ 2, 1 }, .{ 1, 2 } }, ALIVE_DEFAULT);
}
fn spawnTub(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{ .{ 1, 0 }, .{ 0, 1 }, .{ 2, 1 }, .{ 1, 2 } }, ALIVE_DEFAULT);
}

// --- Osciladores ---
fn spawnBlinker(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{ .{ 0, 0 }, .{ 1, 0 }, .{ 2, 0 } }, ALIVE_DEFAULT);
}
fn spawnToad(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{ .{ 1, 0 }, .{ 2, 0 }, .{ 3, 0 }, .{ 0, 1 }, .{ 1, 1 }, .{ 2, 1 } }, ALIVE_DEFAULT);
}
fn spawnBeacon(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{ .{ 0, 0 }, .{ 1, 0 }, .{ 0, 1 }, .{ 1, 1 }, .{ 2, 2 }, .{ 3, 2 }, .{ 2, 3 }, .{ 3, 3 } }, ALIVE_DEFAULT);
}
fn spawnPulsar(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{
        .{ 2, 0 },  .{ 3, 0 },  .{ 4, 0 },  .{ 8, 0 },  .{ 9, 0 },  .{ 10, 0 },
        .{ 0, 2 },  .{ 5, 2 },  .{ 7, 2 },  .{ 12, 2 }, .{ 0, 3 },  .{ 5, 3 },
        .{ 7, 3 },  .{ 12, 3 }, .{ 0, 4 },  .{ 5, 4 },  .{ 7, 4 },  .{ 12, 4 },
        .{ 2, 5 },  .{ 3, 5 },  .{ 4, 5 },  .{ 8, 5 },  .{ 9, 5 },  .{ 10, 5 },
        .{ 2, 7 },  .{ 3, 7 },  .{ 4, 7 },  .{ 8, 7 },  .{ 9, 7 },  .{ 10, 7 },
        .{ 0, 8 },  .{ 5, 8 },  .{ 7, 8 },  .{ 12, 8 }, .{ 0, 9 },  .{ 5, 9 },
        .{ 7, 9 },  .{ 12, 9 }, .{ 0, 10 }, .{ 5, 10 }, .{ 7, 10 }, .{ 12, 10 },
        .{ 2, 12 }, .{ 3, 12 }, .{ 4, 12 }, .{ 8, 12 }, .{ 9, 12 }, .{ 10, 12 },
    }, ALIVE_DEFAULT);
}
fn spawnPentadecathlon(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{
        .{ 2, 0 }, .{ 7, 0 },
        .{ 0, 1 }, .{ 1, 1 },
        .{ 3, 1 }, .{ 4, 1 },
        .{ 5, 1 }, .{ 6, 1 },
        .{ 8, 1 }, .{ 9, 1 },
        .{ 2, 2 }, .{ 7, 2 },
    }, ALIVE_DEFAULT);
}

// --- Naves ---
fn spawnGlider(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{ .{ 1, 0 }, .{ 2, 1 }, .{ 0, 2 }, .{ 1, 2 }, .{ 2, 2 } }, ALIVE_DEFAULT);
}
fn spawnLWSS(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{
        .{ 1, 0 }, .{ 4, 0 },
        .{ 0, 1 }, .{ 0, 2 },
        .{ 4, 2 }, .{ 0, 3 },
        .{ 1, 3 }, .{ 2, 3 },
        .{ 3, 3 },
    }, ALIVE_DEFAULT);
}
fn spawnMWSS(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{
        .{ 2, 0 },
        .{ 0, 1 },
        .{ 4, 1 },
        .{ 5, 2 },
        .{ 0, 3 },
        .{ 5, 3 },
        .{ 1, 4 },
        .{ 2, 4 },
        .{ 3, 4 },
        .{ 4, 4 },
        .{ 5, 4 },
    }, ALIVE_DEFAULT);
}
fn spawnHWSS(fb: *Framebuffer, ox: i32, oy: i32) void {
    spawn(fb, ox, oy, &.{
        .{ 3, 0 }, .{ 4, 0 },
        .{ 1, 1 }, .{ 6, 1 },
        .{ 0, 2 }, .{ 0, 3 },
        .{ 6, 3 }, .{ 0, 4 },
        .{ 1, 4 }, .{ 2, 4 },
        .{ 3, 4 }, .{ 4, 4 },
        .{ 5, 4 },
    }, ALIVE_DEFAULT);
}

fn spawnInitialPattern(fb: *Framebuffer) void {
    spawnBlock(fb, 4, 4);
    spawnBeehive(fb, 4, 12);
    spawnLoaf(fb, 4, 22);
    spawnBoat(fb, 4, 34);
    spawnTub(fb, 4, 44);

    spawnBlinker(fb, 30, 6);
    spawnToad(fb, 30, 14);
    spawnBeacon(fb, 30, 24);
    spawnPulsar(fb, 45, 40);
    spawnPentadecathlon(fb, 30, 60);

    spawnGlider(fb, 70, 5);
    spawnLWSS(fb, 90, 20);
    spawnMWSS(fb, 90, 40);
    spawnHWSS(fb, 90, 60);
}

// -----------------------------------------------------------------------
// Loop principal
// -----------------------------------------------------------------------

pub fn main() void {
    rl.InitWindow(SCREEN_W, SCREEN_H, "Conway's Game of Life - Zig + raylib");
    defer rl.CloseWindow();
    rl.SetTargetFPS(12);

    const buf_a = std.heap.page_allocator.create(Framebuffer) catch unreachable;
    const buf_b = std.heap.page_allocator.create(Framebuffer) catch unreachable;
    defer std.heap.page_allocator.destroy(buf_a);
    defer std.heap.page_allocator.destroy(buf_b);

    buf_a.* = Framebuffer{};
    buf_b.* = Framebuffer{};
    spawnInitialPattern(buf_a);

    var current: *Framebuffer = buf_a;
    var next: *Framebuffer = buf_b;
    var paused = false;

    while (!rl.WindowShouldClose()) {
        if (rl.IsKeyPressed(rl.KEY_SPACE)) paused = !paused;

        if (!paused) {
            nextGeneration(current, next);
            const tmp = current;
            current = next;
            next = tmp;
        }

        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);

        var y: i32 = 0;
        while (y < FB_H) : (y += 1) {
            var x: i32 = 0;
            while (x < FB_W) : (x += 1) {
                const color = get_color(current, x, y);
                if (!isAlive(color)) continue;
                rl.DrawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, color);
            }
        }

        rl.DrawText("SPACE: pausa/reanuda -- colores = hilo que calculo esa celula", 10, 10, 16, rl.GRAY);

        rl.EndDrawing();
    }
}
