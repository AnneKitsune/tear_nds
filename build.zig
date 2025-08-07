const std = @import("std");
const builtin = @import("builtin");

const emulator = "desmume";

pub fn build(b: *std.Build) void {
    const devkitpro = std.process.getEnvVarOwned(b.allocator, "DEVKITPRO") catch {@panic("Missing DEVKITPRO env var.");};
    const devkitarm = std.process.getEnvVarOwned(b.allocator, "DEVKITARM") catch {@panic("Missing DEVKITARM env var.");};
    const optimize = b.standardOptimizeOption(.{});

    const nds_target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm946e_s },
    });

//    const nds_lib_mod = b.createModule(.{
//        .root_source_file = b.path("src/root.zig"),
//        .target = nds_target,
//        .optimize = optimize,
//        .link_libc = true,
//    });

    const nds_ex_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = nds_target,
        .optimize = optimize,
        .link_libc = true,
    });


    var nds_ex_obj = b.addObject(.{
        .name = "zig-nds",
        .root_module = nds_ex_mod,
    });

    nds_ex_obj.setLibCFile(b.path("libc.txt"));
    nds_ex_obj.addIncludePath(.{ .cwd_relative = b.fmt("{s}/libnds/include", .{devkitpro})});
    nds_ex_obj.addIncludePath(.{ .cwd_relative = b.fmt("{s}/portlibs/nds/include", .{devkitpro})});
    nds_ex_obj.addIncludePath(.{ .cwd_relative = b.fmt("{s}/portlibs/armv5te/include", .{devkitpro})});
    nds_ex_obj.addIncludePath(.{ .cwd_relative = b.fmt("{s}/portlibs/armv4t/include", .{devkitpro})});
    nds_ex_obj.addIncludePath(.{ .cwd_relative = b.fmt("{s}/calico/include", .{devkitpro})});

    //const obj_path = obj.getEmittedBin().generated.sub_path;
    const install_obj = b.addInstallBinFile(nds_ex_obj.getEmittedBin(), "zig-nds.o");

    const extension = if (builtin.target.os.tag == .windows) ".exe" else "";
    const elf = b.addSystemCommand(&(.{
        b.fmt("{s}/bin/arm-none-eabi-gcc" ++ extension, .{devkitarm}),
        "-g",
        "-mthumb",
        "-mthumb-interwork",
        "-Wl,-Map,zig-out/zig-nds.map",
        b.fmt("-specs={s}/calico/share/ds9.specs", .{devkitpro}),
        "zig-out/bin/zig-nds.o",
        b.fmt("-L{s}/libnds/lib", .{devkitpro}),
        b.fmt("-L{s}/portlibs/nds/lib", .{devkitpro}),
        b.fmt("-L{s}/portlibs/armv5te/lib", .{devkitpro}),
        b.fmt("-L{s}/portlibs/armv4t/lib", .{devkitpro}),
        b.fmt("-L{s}/calico/lib", .{devkitpro}),
        "-lnds9",
        "-lcalico_ds9",
        "-o",
        "zig-out/zig-nds.elf",
    }));

    const nds = b.addSystemCommand(&.{
        b.fmt("{s}/tools/bin/ndstool" ++ extension, .{devkitpro}),
        "-c",
        "zig-out/zig-nds.nds",
        "-9",
        "zig-out/zig-nds.elf",
        "-7",
        b.fmt("{s}/calico/bin/ds7_maine.elf", .{devkitpro}),
    });

    b.default_step.dependOn(&nds.step);
    nds.step.dependOn(&elf.step);
    elf.step.dependOn(&nds_ex_obj.step);
    elf.step.dependOn(&install_obj.step);

    const run_step = b.step("run", "Run in DeSmuME");
    const desmume = b.addSystemCommand(&.{ emulator, "zig-out/zig-nds.nds" });
    run_step.dependOn(&nds.step);
    run_step.dependOn(&desmume.step);
}

