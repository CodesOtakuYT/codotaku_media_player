const c = @import("c.zig").c;
const checkFF = @import("internal.zig").checkFF;
const Packet = @import("packet.zig");
pub const Frame = @import("frame.zig");

const Self = @This();
ptr: *c.AVCodecContext,

pub fn init(codec_parameters: *c.AVCodecParameters, thread_count: i32) !Self {
    const codec = c.avcodec_find_decoder(codec_parameters.codec_id);
    if (codec == null) return error.NoDecoderFound;

    var context = c.avcodec_alloc_context3(codec);
    if (context == null) return error.NoMemory;
    errdefer c.avcodec_free_context(&context);
    try checkFF(c.avcodec_parameters_to_context(context, codec_parameters));
    context.*.thread_count = thread_count;
    try checkFF(c.avcodec_open2(context, null, null));

    return .{
        .ptr = context.?,
    };
}

pub fn deinit(self: *Self) void {
    var ptr: ?*c.AVCodecContext = self.ptr;
    c.avcodec_free_context(&ptr);
    self.ptr = undefined;
}

pub fn push(self: *Self, packet: Packet) !bool {
    const ret = c.avcodec_send_packet(self.ptr, packet.ptr);
    if (ret == 0) return true;
    if (ret == c.AVERROR_EOF or ret == -c.EAGAIN) return false;
    try checkFF(ret);
    unreachable;
}

pub fn pull(self: *Self, frame: *Frame) !bool {
    const ret = c.avcodec_receive_frame(self.ptr, frame.ptr);
    if (ret == 0) return true;
    if (ret == c.AVERROR_EOF or ret == -c.EAGAIN) return false;
    try checkFF(ret);
    unreachable;
}

pub fn clear(self: *Self) void {
    c.avcodec_flush_buffers(self.ptr);
}

pub fn flush(self: *Self) !void {
    try checkFF(c.avcodec_send_packet(self.ptr, null));
}
