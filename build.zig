const std = @import("std");
const builtin = @import("builtin");

const emulator = "melonDS";

var devkitpro: []u8 = undefined;
var devkitarm: []u8 = undefined;

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    devkitpro = std.process.getEnvVarOwned(b.allocator, "DEVKITPRO") catch {
        @panic("Missing DEVKITPRO env var.");
    };
    devkitarm = std.process.getEnvVarOwned(b.allocator, "DEVKITARM") catch {
        @panic("Missing DEVKITARM env var.");
    };

    //    const nds_lib_mod = b.createModule(.{
    //        .root_source_file = b.path("src/root.zig"),
    //        .target = nds_target,
    //        .optimize = optimize,
    //        .link_libc = true,
    //    });

    // by default, running just `zig build` will create zig-out/zig-nds.nds
    const nds = compileNds(b, .{
        .name = "zig_nds_example",
        .optimize = optimize,
        .root_file = b.path("src/main.zig"),
    });
    b.default_step.dependOn(&nds.step);

    // `zig build run` starts the emulator and runs the game.
    const run_emulator_cmd = b.addSystemCommand(&.{ emulator, "zig-out/bin/zig_nds_example.nds" });
    run_emulator_cmd.step.dependOn(&nds.step);

    const run_step = b.step("run", "Run in an emulator (melonDS)");
    run_step.dependOn(&run_emulator_cmd.step);

    // export lib
    _ = b.addModule("tear_nds", .{
        .root_source_file = b.path("src/root.zig"),
        .target = ndsTarget(b),
        .optimize = optimize,
        .link_libc = true,
    });
    //const nds_lib = b.addLibrary(.{
    //.name = "tear_nds",
    //.root_module = lib_mod,
    //});
    //setDeps(b, nds_lib);
}

fn ndsTarget(b: *std.Build) std.Build.ResolvedTarget {
    return b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm946e_s },
    });
}

fn setDeps(b: *std.Build, step: *std.Build.Step.Compile) void {
    step.addIncludePath(.{ .cwd_relative = b.fmt("{s}/libnds/include", .{devkitpro}) });
    step.addIncludePath(.{ .cwd_relative = b.fmt("{s}/portlibs/nds/include", .{devkitpro}) });
    step.addIncludePath(.{ .cwd_relative = b.fmt("{s}/portlibs/armv5te/include", .{devkitpro}) });
    step.addIncludePath(.{ .cwd_relative = b.fmt("{s}/portlibs/armv4t/include", .{devkitpro}) });
    step.addIncludePath(.{ .cwd_relative = b.fmt("{s}/calico/include", .{devkitpro}) });
    step.addSystemIncludePath(.{ .cwd_relative = b.fmt("{s}/arm-none-eabi/include", .{devkitarm}) });
}

/// Options needed to create the zig module for the nds obj.
pub const NdsOptions = struct {
    name: []const u8,
    optimize: std.builtin.OptimizeMode,
    root_file: std.Build.LazyPath,
    imports: []const std.Build.Module.Import = &.{},
};

pub fn compileNds(b: *std.Build, opts: NdsOptions) *std.Build.Step.Run {
    // code -> .o
    const nds_ex_mod = b.createModule(.{
        .root_source_file = opts.root_file,
        .target = ndsTarget(b),
        .optimize = opts.optimize,
        .link_libc = true,
        .imports = opts.imports,
    });

    var nds_ex_obj = b.addObject(.{
        .name = opts.name,
        .root_module = nds_ex_mod,
    });

    setDeps(b, nds_ex_obj);

    const install_obj = b.addInstallBinFile(nds_ex_obj.getEmittedBin(), b.fmt("{s}.o", .{opts.name}));

    // .o -> .elf
    const extension = if (builtin.target.os.tag == .windows) ".exe" else "";
    const elf = b.addSystemCommand(&(.{
        b.fmt("{s}/bin/arm-none-eabi-gcc" ++ extension, .{devkitarm}),
        "-g",
        "-mthumb",
        "-mthumb-interwork",
        b.fmt("-Wl,-Map,zig-out/{s}.map", .{opts.name}),
        b.fmt("-specs={s}/calico/share/ds9.specs", .{devkitpro}),
        b.fmt("zig-out/bin/{s}.o", .{opts.name}),
        b.fmt("-L{s}/libnds/lib", .{devkitpro}),
        b.fmt("-L{s}/portlibs/nds/lib", .{devkitpro}),
        b.fmt("-L{s}/portlibs/armv5te/lib", .{devkitpro}),
        b.fmt("-L{s}/portlibs/armv4t/lib", .{devkitpro}),
        b.fmt("-L{s}/calico/lib", .{devkitpro}),
        "-lnds9",
        "-lcalico_ds9",
        "-o",
        b.fmt("zig-out/{s}.elf", .{opts.name}),
    }));

    // elf -> .nds
    const nds = b.addSystemCommand(&.{
        b.fmt("{s}/tools/bin/ndstool" ++ extension, .{devkitpro}),
        "-c",
        b.fmt("zig-out/bin/{s}.nds", .{opts.name}),
        "-9",
        b.fmt("zig-out/{s}.elf", .{opts.name}),
        "-7",
        b.fmt("{s}/calico/bin/ds7_maine.elf", .{devkitpro}),
    });

    nds.step.dependOn(&elf.step);
    elf.step.dependOn(&nds_ex_obj.step);
    elf.step.dependOn(&install_obj.step);

    return nds;
}
