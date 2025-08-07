const std = @import("std");
const builtin = @import("builtin");

const emulator = "desmume";

pub fn build(b: *std.Build) void {

    const devkitpro = std.process.getEnvVarOwned(b.allocator, "DEVKITPRO") catch {@panic("Missing DEVKITPRO env var.");};
    const devkitarm = std.process.getEnvVarOwned(b.allocator, "DEVKITARM") catch {@panic("Missing DEVKITARM env var.");};
    //const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nds_target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm946e_s },
    });

    const nds_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = nds_target,
        .optimize = optimize,
        .link_libc = true,
    });


    var obj = b.addObject(.{
        .name = "zig-nds",
        .root_module = nds_mod,
    });

    obj.setLibCFile(b.path("libc.txt"));
    const path1 = std.fmt.allocPrint(b.allocator, "{s}/libnds/include", .{devkitpro}) catch { @panic(""); };
    const path2 = std.fmt.allocPrint(b.allocator, "{s}/portlibs/nds/include", .{devkitpro}) catch { @panic(""); };
    const path3 = std.fmt.allocPrint(b.allocator, "{s}/portlibs/armv5te/include", .{devkitpro}) catch { @panic(""); };
    const path12 = std.fmt.allocPrint(b.allocator, "{s}/portlibs/armv4t/include", .{devkitpro}) catch { @panic(""); };
    const calico_path = std.fmt.allocPrint(b.allocator, "{s}/calico/include", .{devkitpro}) catch { @panic(""); };
    obj.addIncludePath(.{ .cwd_relative = path1});
    obj.addIncludePath(.{ .cwd_relative = path2});
    obj.addIncludePath(.{ .cwd_relative = path3});
    obj.addIncludePath(.{ .cwd_relative = path12});
    obj.addIncludePath(.{ .cwd_relative = calico_path});

    //const obj_path = obj.getEmittedBin().generated.sub_path;
    const install_obj = b.addInstallBinFile(obj.getEmittedBin(), "zig-nds.o");

    const extension = if (builtin.target.os.tag == .windows) ".exe" else "";
    const path4 = std.fmt.allocPrint(b.allocator, "{s}/bin/arm-none-eabi-gcc" ++ extension, .{devkitarm}) catch { @panic(""); };
    //const path5 = std.fmt.allocPrint(b.allocator, "-specs={s}/arm-none-eabi/lib/ds_arm9.specs", .{devkitarm}) catch { @panic(""); };
    const path5_2 = std.fmt.allocPrint(b.allocator, "-specs={s}/calico/share/ds9.specs", .{devkitpro}) catch { @panic(""); };
    const path6 = std.fmt.allocPrint(b.allocator, "-L{s}/libnds/lib", .{devkitpro}) catch { @panic(""); };
    const path7 = std.fmt.allocPrint(b.allocator, "-L{s}/portlibs/nds/lib", .{devkitpro}) catch { @panic(""); };
    const path8 = std.fmt.allocPrint(b.allocator, "-L{s}/portlibs/armv5te/lib", .{devkitpro}) catch { @panic(""); };
    const path11 = std.fmt.allocPrint(b.allocator, "-L{s}/portlibs/armv4t/lib", .{devkitpro}) catch { @panic(""); };
    const calico_path2 = std.fmt.allocPrint(b.allocator, "-L{s}/calico/lib", .{devkitpro}) catch { @panic(""); };
    const elf = b.addSystemCommand(&(.{
        path4,
        "-g",
        "-mthumb",
        "-mthumb-interwork",
        "-Wl,-Map,zig-out/zig-nds.map",
        //path5,
        path5_2,
        "zig-out/bin/zig-nds.o",
        path6,
        path7,
        path8,
        path11,
        calico_path2,
        "-lnds9",
        "-lcalico_ds9",
        "-o",
        "zig-out/zig-nds.elf",
    }));

    const path9 = std.fmt.allocPrint(b.allocator, "{s}/tools/bin/ndstool" ++ extension, .{devkitpro}) catch { @panic(""); };
    const calico_path3 = std.fmt.allocPrint(b.allocator, "{s}/calico/bin/ds7_maine.elf", .{devkitpro}) catch { @panic(""); };
    const nds = b.addSystemCommand(&.{
        path9,
        "-c",
        "zig-out/zig-nds.nds",
        "-9",
        "zig-out/zig-nds.elf",
        "-7",
        calico_path3,
    });
    //nds.stdout_action = .ignore;

    b.default_step.dependOn(&nds.step);
    nds.step.dependOn(&elf.step);
    elf.step.dependOn(&obj.step);
    elf.step.dependOn(&install_obj.step);

    const run_step = b.step("run", "Run in DeSmuME");
    const desmume = b.addSystemCommand(&.{ emulator, "zig-out/zig-nds.nds" });
    run_step.dependOn(&nds.step);
    run_step.dependOn(&desmume.step);
}

