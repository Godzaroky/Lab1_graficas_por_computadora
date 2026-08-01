const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // raylib se descarga y compila como dependencia via el package manager de Zig
    const raylib_dep = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib_lib = raylib_dep.artifact("raylib");

    const exe_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .name = "polygon_fill",
        .root_module = exe_module,
    });

    // Desde Zig 0.15/0.16, linkLibrary/addIncludePath viven en root_module,
    // ya no directamente en el Compile step (exe).
    exe.root_module.linkLibrary(raylib_lib);
    exe.root_module.addIncludePath(raylib_dep.path("src"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Compila y ejecuta el laboratorio de relleno de poligonos");
    run_step.dependOn(&run_cmd.step);
}
