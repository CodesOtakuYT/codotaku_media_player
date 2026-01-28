const c = @import("c.zig").c;
const checkFF = @import("internal.zig").checkFF;

const Self = @This();
ptr: *c.AVFrame,

pub fn init() !Self {
    const ptr = c.av_frame_alloc();
    if (ptr == null) {
        try checkFF(c.AVERROR(c.ENOMEM));
        unreachable;
    }
    return .{
        .ptr = ptr.?,
    };
}

pub fn deinit(self: *Self) void {
    var ptr: ?*c.AVFrame = self.ptr;
    c.av_frame_free(&ptr);
}
