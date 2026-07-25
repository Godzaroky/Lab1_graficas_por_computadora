const std = @import("std");

pub const Point = struct {
    x: f32,
    y: f32,
};

/// Rellena un polígono de N vértices (convexo o no, incluso con "agujeros"
/// representados mediante un puente/slit que conecta el contorno exterior
/// con el interior) usando el algoritmo de scanline con regla par-impar.
pub fn fillPolygon(
    allocator: std.mem.Allocator,
    points: []const Point,
    setPixel: *const fn (x: i32, y: i32) void,
) !void {
    if (points.len < 3) return;

    var min_y: f32 = points[0].y;
    var max_y: f32 = points[0].y;
    for (points) |p| {
        if (p.y < min_y) min_y = p.y;
        if (p.y > max_y) max_y = p.y;
    }

    const y_start: i32 = @intFromFloat(@ceil(min_y));
    const y_end: i32 = @intFromFloat(@floor(max_y));

    var intersections: std.ArrayList(f32) = .empty;
    defer intersections.deinit(allocator);

    var y = y_start;
    while (y <= y_end) : (y += 1) {
        intersections.clearRetainingCapacity();
        const yf: f32 = @floatFromInt(y);

        var i: usize = 0;
        while (i < points.len) : (i += 1) {
            const p1 = points[i];
            const p2 = points[(i + 1) % points.len];

            if (p1.y == p2.y) continue;

            if ((yf >= p1.y and yf < p2.y) or (yf >= p2.y and yf < p1.y)) {
                const t = (yf - p1.y) / (p2.y - p1.y);
                const x = p1.x + t * (p2.x - p1.x);
                try intersections.append(allocator, x);
            }
        }

        std.mem.sort(f32, intersections.items, {}, std.sort.asc(f32));

        var j: usize = 0;
        while (j + 1 < intersections.items.len) : (j += 2) {
            const x_start: i32 = @intFromFloat(@round(intersections.items[j]));
            const x_end: i32 = @intFromFloat(@round(intersections.items[j + 1]));
            var x = x_start;
            while (x < x_end) : (x += 1) {
                setPixel(x, y);
            }
        }
    }
}

/// Utilidad para rellenar varios polígonos independientes en una sola llamada
pub fn fillPolygons(
    allocator: std.mem.Allocator,
    polygons: []const []const Point,
    setPixel: *const fn (x: i32, y: i32) void,
) !void {
    for (polygons) |poly| {
        try fillPolygon(allocator, poly, setPixel);
    }
}
