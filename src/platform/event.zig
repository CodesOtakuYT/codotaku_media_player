const c = @import("c.zig").c;
const checkSDL = @import("internal.zig").checkSDL;

pub const Event = union(enum) {
    quit,
    other,

    pub fn poll() ?Event {
        var event: c.SDL_Event = undefined;
        if (c.SDL_PollEvent(&event)) {
            return switch (event.type) {
                c.SDL_EVENT_QUIT => .quit,
                else => .other,
            };
        }
        return null;
    }
};
