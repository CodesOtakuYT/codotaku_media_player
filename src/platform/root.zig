pub const Window = @import("window.zig");
pub const Event = @import("event.zig").Event;

const c = @import("c.zig").c;
const checkSDL = @import("internal.zig").checkSDL;

pub fn init() !void {
    try checkSDL(c.SDL_Init(c.SDL_INIT_VIDEO));
}

pub fn deinit() void {
    c.SDL_Quit();
}
