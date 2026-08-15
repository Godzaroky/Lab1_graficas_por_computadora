pub const packages = struct {
    pub const @"N-V-__8AAJl1DwBezhYo_VE6f53mPVm00R-Fk28NPW7P14EQ" = struct {
        pub const build_root = "C:\\Users\\azovg\\zig\\src\\Lab1_graficas_por_computadora\\game_of_life\\zig-pkg\\N-V-__8AAJl1DwBezhYo_VE6f53mPVm00R-Fk28NPW7P14EQ";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"N-V-__8AALShqgXkvqYU6f__FrA22SMWmi2TXCJjNTO1m8XJ" = struct {
        pub const available = false;
    };
    pub const @"N-V-__8AAPPCmABYkTrLoRGTR6whFQP1bvg7p5vpLsKIcn4G" = struct {
        pub const available = false;
    };
    pub const @"raylib-6.0.0-whq8uIPTKwXybRNNu7BJNM6bxip5fYUgAh-bctTa7oHR" = struct {
        pub const build_root = "C:\\Users\\azovg\\zig\\src\\Lab1_graficas_por_computadora\\game_of_life\\zig-pkg\\raylib-6.0.0-whq8uIPTKwXybRNNu7BJNM6bxip5fYUgAh-bctTa7oHR";
        pub const build_zig = @import("raylib-6.0.0-whq8uIPTKwXybRNNu7BJNM6bxip5fYUgAh-bctTa7oHR");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "xcode_frameworks", "N-V-__8AALShqgXkvqYU6f__FrA22SMWmi2TXCJjNTO1m8XJ" },
            .{ "raygui", "N-V-__8AAPPCmABYkTrLoRGTR6whFQP1bvg7p5vpLsKIcn4G" },
            .{ "emsdk", "N-V-__8AAJl1DwBezhYo_VE6f53mPVm00R-Fk28NPW7P14EQ" },
            .{ "zemscripten", "zemscripten-0.2.0-dev-sRlDqApRAACspTbAZnuNKWIzfWzSYgYkb2nWAXZ-tqqt" },
        };
    };
    pub const @"zemscripten-0.2.0-dev-sRlDqApRAACspTbAZnuNKWIzfWzSYgYkb2nWAXZ-tqqt" = struct {
        pub const build_root = "C:\\Users\\azovg\\zig\\src\\Lab1_graficas_por_computadora\\game_of_life\\zig-pkg\\zemscripten-0.2.0-dev-sRlDqApRAACspTbAZnuNKWIzfWzSYgYkb2nWAXZ-tqqt";
        pub const build_zig = @import("zemscripten-0.2.0-dev-sRlDqApRAACspTbAZnuNKWIzfWzSYgYkb2nWAXZ-tqqt");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "raylib", "raylib-6.0.0-whq8uIPTKwXybRNNu7BJNM6bxip5fYUgAh-bctTa7oHR" },
};
