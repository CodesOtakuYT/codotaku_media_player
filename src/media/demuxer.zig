const c = @import("c.zig").c;
const checkFF = @import("internal.zig").checkFF;
const Packet = @import("packet.zig");

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

pub const Stream = struct {
    ptr: *c.AVStream,

    pub const Info = union(enum) {
        video: struct {
            bitrate: i64,
            width: i32,
            height: i32,
            fps: f64,
        },
        audio: struct {
            bitrate: i64,
            channels: i32,
            sample_rate: i32,
        },
        other: c.AVMediaType,
    };

    pub fn info(self: Stream) Info {
        const par = self.ptr.codecpar.*;
        return switch (par.codec_type) {
            c.AVMEDIA_TYPE_VIDEO => .{
                .video = .{
                    .bitrate = par.bit_rate,
                    .width = par.width,
                    .height = par.height,
                    .fps = c.av_q2d(self.ptr.avg_frame_rate),
                },
            },
            c.AVMEDIA_TYPE_AUDIO => .{
                .audio = .{
                    .bitrate = par.bit_rate,
                    .channels = par.ch_layout.nb_channels,
                    .sample_rate = par.sample_rate,
                },
            },
            else => .{
                .other = par.codec_type,
            },
        };
    }
};

pub fn streams(self: *Self) []Stream {
    return @ptrCast(self.ptr.streams[0..self.ptr.nb_streams]);
}

pub fn streamFromPacket(self: *Self, packet: Packet) Stream {
    return self.streams()[@intCast(packet.ptr.stream_index)];
}

pub fn bestStream(self: *Self, media_type: c.AVMediaType, related_stream: ?Stream) !Stream {
    const ret = c.av_find_best_stream(
        self.ptr,
        media_type,
        -1,
        if (related_stream) |s| s.ptr.index else -1,
        null,
        0,
    );
    try checkFF(ret);
    return self.streams()[@intCast(ret)];
}

const std = @import("std");

test "hello" {
    var demuxer = try @This().init(
        "/home/codotaku/2026-01-24 07-16-00.mp4",
    );
    defer demuxer.deinit();

    var packet = try Packet.init();
    defer packet.deinit();

    while (try demuxer.next(&packet)) {
        var stream = demuxer.streamFromPacket(packet);
        switch (stream.info()) {
            .video => std.debug.print("V", .{}),
            .audio => std.debug.print("A", .{}),
            .other => std.debug.print(".", .{}),
        }
    }

    for (demuxer.streams()) |stream| {
        std.debug.print("{any}\n", .{stream.info()});
    }

    const video_stream = try demuxer.bestStream(c.AVMEDIA_TYPE_VIDEO, null);
    const audio_stream = try demuxer.bestStream(c.AVMEDIA_TYPE_AUDIO, video_stream);

    std.debug.print("best video stream: {}", .{video_stream.info()});
    std.debug.print("best audio stream: {}", .{audio_stream.info()});
}
