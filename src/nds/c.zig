pub const c = @cImport({
    //@cDefine("ARM7", {}); // TODO: This should be ARM9, but translate-c doesn't work for now
    @cDefine("ARM9", {});
    @cDefine("__NDS__", {});
    @cInclude("nds.h");
    @cInclude("stdio.h");
});

