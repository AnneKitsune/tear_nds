const std = @import("std");
const builtin = @import("builtin");

const emulator = "desmume";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    //    const nds_lib_mod = b.createModule(.{
    //        .root_source_file = b.path("src/root.zig"),
    //        .target = nds_target,
    //        .optimize = optimize,
    //        .link_libc = true,
    //    });

    // by default, running just `zig build` will create zig-out/zig-nds.nds
    const nds = compileNds(b, "src/main.zig", optimize, "zig-nds");
    b.default_step.dependOn(&nds.step);

    const run_emulator_cmd = b.addSystemCommand(&.{ emulator, "zig-out/zig-nds.nds" });
    run_emulator_cmd.step.dependOn(&nds.step);

    const run_step = b.step("run", "Run in an emulator (desmume)");
    run_step.dependOn(&run_emulator_cmd.step);
}

pub fn compileNds(b: *std.Build, root_file: []const u8, optimize: std.builtin.OptimizeMode, name: []const u8) *std.Build.Step.Run {
    const devkitpro = std.process.getEnvVarOwned(b.allocator, "DEVKITPRO") catch {
        @panic("Missing DEVKITPRO env var.");
    };
    const devkitarm = std.process.getEnvVarOwned(b.allocator, "DEVKITARM") catch {
        @panic("Missing DEVKITARM env var.");
    };

    // cpu target of the nds
    const nds_target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm946e_s },
    });

    // code -> .o
    const nds_ex_mod = b.createModule(.{
        .root_source_file = b.path(root_file),
        .target = nds_target,
        .optimize = optimize,
        .link_libc = true,
    });

    var nds_ex_obj = b.addObject(.{
        .name = name,
        .root_module = nds_ex_mod,
    });

    nds_ex_obj.addIncludePath(.{ .cwd_relative = b.fmt("{s}/libnds/include", .{devkitpro}) });
    nds_ex_obj.addIncludePath(.{ .cwd_relative = b.fmt("{s}/portlibs/nds/include", .{devkitpro}) });
    nds_ex_obj.addIncludePath(.{ .cwd_relative = b.fmt("{s}/portlibs/armv5te/include", .{devkitpro}) });
    nds_ex_obj.addIncludePath(.{ .cwd_relative = b.fmt("{s}/portlibs/armv4t/include", .{devkitpro}) });
    nds_ex_obj.addIncludePath(.{ .cwd_relative = b.fmt("{s}/calico/include", .{devkitpro}) });
    nds_ex_obj.addSystemIncludePath(.{ .cwd_relative = b.fmt("{s}/arm-none-eabi/include", .{devkitarm}) });

    const install_obj = b.addInstallBinFile(nds_ex_obj.getEmittedBin(), b.fmt("{s}.o", .{name}));

    // .o -> .elf
    const extension = if (builtin.target.os.tag == .windows) ".exe" else "";
    const elf = b.addSystemCommand(&(.{
        b.fmt("{s}/bin/arm-none-eabi-gcc" ++ extension, .{devkitarm}),
        "-g",
        "-mthumb",
        "-mthumb-interwork",
        b.fmt("-Wl,-Map,zig-out/{s}.map", .{name}),
        b.fmt("-specs={s}/calico/share/ds9.specs", .{devkitpro}),
        b.fmt("zig-out/bin/{s}.o", .{name}),
        b.fmt("-L{s}/libnds/lib", .{devkitpro}),
        b.fmt("-L{s}/portlibs/nds/lib", .{devkitpro}),
        b.fmt("-L{s}/portlibs/armv5te/lib", .{devkitpro}),
        b.fmt("-L{s}/portlibs/armv4t/lib", .{devkitpro}),
        b.fmt("-L{s}/calico/lib", .{devkitpro}),
        "-lnds9",
        "-lcalico_ds9",
        "-o",
        b.fmt("zig-out/{s}.elf", .{name}),
    }));

    // elf -> .nds
    const nds = b.addSystemCommand(&.{
        b.fmt("{s}/tools/bin/ndstool" ++ extension, .{devkitpro}),
        "-c",
        b.fmt("zig-out/bin/{s}.nds", .{name}),
        "-9",
        b.fmt("zig-out/{s}.elf", .{name}),
        "-7",
        b.fmt("{s}/calico/bin/ds7_maine.elf", .{devkitpro}),
    });

    nds.step.dependOn(&elf.step);
    elf.step.dependOn(&nds_ex_obj.step);
    elf.step.dependOn(&install_obj.step);

    return nds;
}
