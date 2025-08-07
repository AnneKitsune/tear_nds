const c = @import("nds/c.zig").c;

export fn vblank() void {}

export fn main(_: c_int, _: [*]const [*:0]const u8) void {
    c.irqSet(c.IRQ_VBLANK, vblank);
    _ = c.consoleDemoInit();

    _ = c.iprintf("Hello World!\n");
    while (true) {
        c.swiWaitForVBlank();
    }
}
