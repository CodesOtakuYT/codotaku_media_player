const c = @import("c.zig").c;
const checkSDL = @import("internal.zig").checkSDL;
const Window = @import("window.zig");

const Self = @This();
ptr: *c.SDL_Texture,

pub fn init(window: *Window, dimensions: [2]i32) !Self {
    const ptr = c.SDL_CreateTexture(
        window.renderer,
        c.SDL_PIXELFORMAT_YV12,
        c.SDL_TEXTUREACCESS_STREAMING,
        dimensions[0],
        dimensions[1],
    );
    if (ptr == null) return error.TextureCreationFailed;
    errdefer c.SDL_DestroyTexture(ptr);

    return .{
        .ptr = ptr,
    };
}

pub fn deinit(self: *Self) void {
    c.SDL_DestroyTexture(self.ptr);
}

pub fn updateYuv(self: *Self, data: [3][*]const u8, stride: [3]i32) !void {
    try checkSDL(c.SDL_UpdateYUVTexture(
        self.ptr,
        null,
        data[0],
        stride[0],
        data[1],
        stride[1],
        data[2],
        stride[2],
    ));
}

pub fn render(self: *Self) !void {
    const renderer = c.SDL_GetRendererFromTexture(self.ptr).?;
    try checkSDL(c.SDL_RenderTexture(renderer, self.ptr, null, null));
}
