const c = @import("c.zig").c;
const checkSDL = @import("internal.zig").checkSDL;

const Self = @This();

window: *c.SDL_Window,
renderer: *c.SDL_Renderer,

pub fn init(title: [:0]const u8, width: i32, height: i32, is_resizable: bool) !Self {
    var window_flags: c.SDL_WindowFlags = c.SDL_WINDOW_HIDDEN;
    if (is_resizable) window_flags |= c.SDL_WINDOW_RESIZABLE;
    var window: ?*c.SDL_Window = undefined;
    var renderer: ?*c.SDL_Renderer = undefined;
    try checkSDL(c.SDL_CreateWindowAndRenderer(
        title,
        width,
        height,
        window_flags,
        &window,
        &renderer,
    ));
    errdefer c.SDL_DestroyRenderer(renderer);
    errdefer c.SDL_DestroyWindow(window);
    return .{
        .window = window.?,
        .renderer = renderer.?,
    };
}

pub fn deinit(self: *Self) void {
    c.SDL_DestroyRenderer(self.renderer);
    c.SDL_DestroyWindow(self.window);
}

pub fn show(self: *Self) !void {
    try checkSDL(c.SDL_ShowWindow(self.window));
}

const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

pub fn clear(self: *Self, color: Color) !void {
    try checkSDL(c.SDL_SetRenderDrawColorFloat(
        self.renderer,
        color.r,
        color.g,
        color.b,
        color.a,
    ));
    try checkSDL(c.SDL_RenderClear(self.renderer));
}

pub fn present(self: *Self) !void {
    try checkSDL(c.SDL_RenderPresent(self.renderer));
}
