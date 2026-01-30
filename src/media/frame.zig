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

pub fn isVideo(self: *const Self) bool {
    return self.ptr.width > 0;
}

pub fn yuvData(self: *const Self) [3][*]const u8 {
    const data = self.ptr.data;
    return .{ data[0], data[1], data[2] };
}

pub fn stride(self: *const Self) [3]i32 {
    const linesize = self.ptr.linesize;
    return .{ linesize[0], linesize[1], linesize[2] };
}
