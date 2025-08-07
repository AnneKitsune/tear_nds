const c = @import("nds/c.zig").c;

export fn main(_: c_int, _: [*]const [*:0]const u8) void {
    _ = c.videoSetMode(c.MODE_0_2D);
    _ = c.videoSetModeSub(c.MODE_0_2D);

    _ = c.vramSetBankA(c.VRAM_A_MAIN_BG);
    _ = c.vramSetBankC(c.VRAM_C_SUB_BG);

    _ = c.dmaFillHalfWords(0, c.VRAM_A, 128 * 1024);
    _ = c.setBackdropColor(c.RGB15(0, 0, 0));

    var top_screen: c.PrintConsole = undefined;
    var bottom_screen: c.PrintConsole = undefined;
    _ = c.consoleInit(&top_screen, 3, c.BgType_Text4bpp, c.BgSize_T_256x256, 31, 0, true, true);
    _ = c.consoleInit(&bottom_screen, 3, c.BgType_Text4bpp, c.BgSize_T_256x256, 31, 0, false, true);

    _ = c.consoleSelect(&top_screen);
    _ = c.iprintf("Hello World!\n");
    _ = c.consoleSelect(&bottom_screen);
    _ = c.iprintf("   \x1b[32mTear NDS by AnneKitsune\n\x1b[39m");

    while (c.pmMainLoop()) {
        c.swiWaitForVBlank();
    }
}
