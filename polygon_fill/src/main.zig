const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const SCREEN_W: i32 = 800;
const SCREEN_H: i32 = 450;

// Maximo de intersecciones por linea de barrido. Con polígonos de hasta
// ~120 vertices sobra de sobra; se puede subir si algun polígono creciera.
const MAX_INTERSECTIONS = 256;

const Point = struct { x: f32, y: f32 };

const Polygon = struct {
    points: []const Point,
    fill: rl.Color,
    line: rl.Color,
};

// -----------------------------------------------------------------------
// Algoritmo de relleno por lineas de barrido (scanline fill).
//
// Funciona para cualquier poligono simple (convexo o concavo), incluyendo
// el "agujero" del Poligono 4: ese agujero esta construido con la tecnica
// del corte/ranura (slit) -- el mismo contorno de puntos entra y sale de
// la cavidad interior -- por lo que un scanline generico y correcto ya
// deja esa zona sin pintar, sin necesidad de un caso especial.
//
// Para cada fila (scanline) 'y':
//   1. Se recorren todas las aristas del poligono.
//   2. Se calcula en que 'x' cruza cada arista esa fila (interseccion).
//   3. Se ordenan esas intersecciones de izquierda a derecha.
//   4. Se pinta por pares: [x0,x1] pintado, [x1,x2] vacio, [x2,x3]
// -----------------------------------------------------------------------
fn scanlineFill(polygon: Polygon) void {
    const n = polygon.points.len;
    if (n < 3) return;

    var ymin: f32 = polygon.points[0].y;
    var ymax: f32 = polygon.points[0].y;
    for (polygon.points) |p| {
        if (p.y < ymin) ymin = p.y;
        if (p.y > ymax) ymax = p.y;
    }

    const y_start: i32 = @intFromFloat(@ceil(ymin));
    const y_end: i32 = @intFromFloat(@floor(ymax));

    var xs: [MAX_INTERSECTIONS]f32 = undefined;

    var y = y_start;
    while (y <= y_end) : (y += 1) {
        var count: usize = 0;
        const fy: f32 = @floatFromInt(y);

        var i: usize = 0;
        while (i < n) : (i += 1) {
            const p1 = polygon.points[i];
            const p2 = polygon.points[(i + 1) % n];
            const y1 = p1.y;
            const y2 = p2.y;

            // Intervalo semi-abierto [min(y1,y2), max(y1,y2)) para no
            // contar dos veces un vertice compartido por dos aristas,
            // y para ignorar automaticamente las aristas horizontales.
            if ((y1 <= fy and y2 > fy) or (y2 <= fy and y1 > fy)) {
                const t = (fy - y1) / (y2 - y1);
                const x = p1.x + t * (p2.x - p1.x);
                if (count < xs.len) {
                    xs[count] = x;
                    count += 1;
                }
            }
        }

        std.mem.sort(f32, xs[0..count], {}, std.sort.asc(f32));

        var j: usize = 0;
        while (j + 1 < count) : (j += 2) {
            // ceil/floor (en vez de round) para quedarnos dentro del
            // borde real y no pintar por fuera de la linea del poligono.
            const x_start: i32 = @intFromFloat(@ceil(xs[j]));
            const x_end: i32 = @intFromFloat(@floor(xs[j + 1]));
            var x = x_start;
            while (x <= x_end) : (x += 1) {
                rl.DrawPixel(x, y, polygon.fill);
            }
        }
    }
}

fn drawOutline(polygon: Polygon) void {
    const n = polygon.points.len;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        const p1 = polygon.points[i];
        const p2 = polygon.points[(i + 1) % n];
        rl.DrawLine(
            @intFromFloat(p1.x),
            @intFromFloat(p1.y),
            @intFromFloat(p2.x),
            @intFromFloat(p2.y),
            polygon.line,
        );
    }
}

// --- Datos de los poligonos (tomados directamente del enunciado) --------

const poly1_pts = [_]Point{
    .{ .x = 165, .y = 380 }, .{ .x = 185, .y = 360 }, .{ .x = 180, .y = 330 },
    .{ .x = 207, .y = 345 }, .{ .x = 233, .y = 330 }, .{ .x = 230, .y = 360 },
    .{ .x = 250, .y = 380 }, .{ .x = 220, .y = 385 }, .{ .x = 205, .y = 410 },
    .{ .x = 193, .y = 383 },
};

const poly2_pts = [_]Point{
    .{ .x = 321, .y = 335 }, .{ .x = 288, .y = 286 },
    .{ .x = 339, .y = 251 }, .{ .x = 374, .y = 302 },
};

const poly3_pts = [_]Point{
    .{ .x = 377, .y = 249 }, .{ .x = 411, .y = 197 }, .{ .x = 436, .y = 249 },
};

// Poligono 4: contiene el "agujero" hecho con tecnica de ranura (slit).
const poly4_pts = [_]Point{
    .{ .x = 413, .y = 177 }, .{ .x = 448, .y = 159 }, .{ .x = 502, .y = 88 },
    .{ .x = 553, .y = 53 },  .{ .x = 535, .y = 36 },  .{ .x = 676, .y = 37 },
    .{ .x = 660, .y = 52 },  .{ .x = 750, .y = 145 }, .{ .x = 761, .y = 179 },
    .{ .x = 672, .y = 192 }, .{ .x = 659, .y = 214 }, .{ .x = 615, .y = 214 },
    .{ .x = 632, .y = 230 }, .{ .x = 580, .y = 230 }, .{ .x = 597, .y = 215 },
    .{ .x = 552, .y = 214 }, .{ .x = 517, .y = 144 }, .{ .x = 466, .y = 180 },
};

const poly5_pts = [_]Point{
    .{ .x = 682, .y = 175 }, .{ .x = 708, .y = 120 },
    .{ .x = 735, .y = 148 }, .{ .x = 739, .y = 170 },
};

pub fn main() void {
    rl.InitWindow(SCREEN_W, SCREEN_H, "Lab - Relleno de Poligonos (Scanline) - Zig + raylib");
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    // Asigna aqui el color de relleno/linea que corresponda a cada
    // poligono segun lo que pida tu enunciado especifico.
    const polygons = [_]Polygon{
        .{ .points = &poly1_pts, .fill = rl.SKYBLUE, .line = rl.DARKBLUE },
        .{ .points = &poly2_pts, .fill = rl.GREEN, .line = rl.DARKGREEN },
        .{ .points = &poly3_pts, .fill = rl.YELLOW, .line = rl.ORANGE },
        .{ .points = &poly4_pts, .fill = rl.PINK, .line = rl.MAROON },
        .{ .points = &poly5_pts, .fill = rl.PURPLE, .line = rl.VIOLET },
    };

    var saved = false;

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        for (polygons) |poly| {
            scanlineFill(poly);
            drawOutline(poly);
        }

        rl.DrawText("Lab: Scanline Polygon Fill - presiona S para guardar out.png", 10, 10, 16, rl.DARKGRAY);

        rl.EndDrawing();

        // Guarda out.png automaticamente en el primer frame, y tambien
        // permite volver a guardarlo a mano con la tecla S.
        if (!saved or rl.IsKeyPressed(rl.KEY_S)) {
            rl.TakeScreenshot("out.png");
            saved = true;
        }
    }
}
