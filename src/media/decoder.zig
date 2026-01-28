const c = @import("c.zig").c;
const checkFF = @import("internal.zig").checkFF;
const Packet = @import("packet.zig");
const Frame = @import("frame.zig");

const Self = @This();
ptr: *c.AVCodecContext,

pub fn init(codec_parameters: *c.AVCodecParameters) !Self {
    const codec = c.avcodec_find_decoder(codec_parameters.codec_id);
    if (codec == null) return error.NoDecoderFound;

    var context = c.avcodec_alloc_context3(codec);
    if (context == null) return error.NoMemory;
    errdefer c.avcodec_free_context(&context);

    try checkFF(c.avcodec_parameters_to_context(context, codec_parameters));

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

test "hello" {
    const std = @import("std");
    const Demuxer = @import("demuxer.zig");
    var demuxer = try Demuxer.init(
        "/home/codotaku/2026-01-24 07-16-00.mp4",
    );
    defer demuxer.deinit();

    const video_stream = try demuxer.bestStream(c.AVMEDIA_TYPE_VIDEO, null);
    const audio_stream = try demuxer.bestStream(c.AVMEDIA_TYPE_AUDIO, video_stream);

    var video_decoder = try Self.init(video_stream.codec_parameters());
    var audio_decoder = try Self.init(audio_stream.codec_parameters());

    var packet = try Packet.init();
    defer packet.deinit();

    var frame = try Frame.init();
    defer frame.deinit();

    while (try demuxer.next(&packet)) {
        const decoder = if (packet.stream_index() == video_stream.index())
            &video_decoder
        else if (packet.stream_index() == audio_stream.index())
            &audio_decoder
        else
            continue;

        var sent = false;
        while (!sent) {
            sent = try decoder.push(packet);
            while (try decoder.pull(&frame)) {
                if (packet.stream_index() == video_stream.index()) {
                    const p: u8 = switch (frame.ptr.pict_type) {
                        c.AV_PICTURE_TYPE_I => 'I',
                        c.AV_PICTURE_TYPE_P => 'P',
                        c.AV_PICTURE_TYPE_B => 'B',
                        else => '.',
                    };
                    std.debug.print("{c}", .{p});
                }
            }
        }
    }
}
