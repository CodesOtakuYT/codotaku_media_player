const c = @import("c.zig").c;
const checkFF = @import("internal.zig").checkFF;
pub const Packet = @import("packet.zig");
pub const Stream = @import("stream.zig");

const Self = @This();
ptr: *c.AVFormatContext,

pub fn init(url: [:0]const u8) !Self {
    var ptr: ?*c.AVFormatContext = null;
    try checkFF(c.avformat_open_input(&ptr, url, null, null));
    errdefer c.avformat_close_input(&ptr);

    try checkFF(c.avformat_find_stream_info(ptr, null));
    return .{
        .ptr = ptr.?,
    };
}

pub fn deinit(self: *Self) void {
    var ptr: ?*c.AVFormatContext = self.ptr;
    c.avformat_close_input(&ptr);
}

pub fn next(self: *Self, packet: *Packet) !bool {
    const ret = c.av_read_frame(self.ptr, packet.ptr);
    if (ret == c.AVERROR_EOF) return false;
    try checkFF(ret);
    return true;
}

pub fn streams(self: *Self) []Stream {
    return @ptrCast(self.ptr.streams[0..self.ptr.nb_streams]);
}

pub fn streamFromPacket(self: *Self, packet: Packet) Stream {
    return self.streams()[@intCast(packet.stream_index())];
}

pub fn bestStream(self: *Self, media_type: c.AVMediaType, related_stream: ?Stream) !Stream {
    const ret = c.av_find_best_stream(
        self.ptr,
        media_type,
        -1,
        if (related_stream) |s| @intCast(s.index()) else -1,
        null,
        0,
    );
    try checkFF(ret);
    return self.streams()[@intCast(ret)];
}
