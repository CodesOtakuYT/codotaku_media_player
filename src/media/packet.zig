const c = @import("c.zig").c;
const checkFF = @import("internal.zig").checkFF;

const Self = @This();
ptr: *c.AVPacket,

pub fn init() !Self {
    const ptr = c.av_packet_alloc();
    if (ptr == null) {
        try checkFF(c.AVERROR(c.ENOMEM));
        unreachable;
    }
    return .{
        .ptr = ptr.?,
    };
}

pub fn deinit(self: *Self) void {
    var ptr: ?*c.AVPacket = self.ptr;
    c.av_packet_free(&ptr);
}

pub fn unref(self: *Self) void {
    c.av_packet_unref(self.ptr);
}

pub fn stream_index(self: Self) usize {
    return @intCast(self.ptr.stream_index);
}
