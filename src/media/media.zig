const Demuxer = @import("demuxer.zig");
const Decoder = @import("decoder.zig");

const Self = @This();
demuxer: Demuxer,
video_stream: Demuxer.Stream,
audio_stream: Demuxer.Stream,
video_decoder: Decoder,
audio_decoder: Decoder,
packet: Demuxer.Packet,
frame: Decoder.Frame,
is_pending_packet: bool = false,
is_flushed: bool = false,

pub fn init(url: [:0]const u8) !Self {
    var demuxer = try Demuxer.init(url);
    errdefer demuxer.deinit();

    const video_stream = try demuxer.bestStream(0, null);
    const audio_stream = try demuxer.bestStream(1, video_stream);

    var video_decoder = try Decoder.init(video_stream.codec_parameters(), 0);
    errdefer video_decoder.deinit();

    var audio_decoder = try Decoder.init(audio_stream.codec_parameters(), 1);
    errdefer audio_decoder.deinit();

    var packet = try Demuxer.Packet.init();
    errdefer packet.deinit();

    var frame = try Decoder.Frame.init();
    errdefer frame.deinit();

    return .{
        .demuxer = demuxer,
        .video_stream = video_stream,
        .audio_stream = audio_stream,
        .video_decoder = video_decoder,
        .audio_decoder = audio_decoder,
        .packet = packet,
        .frame = frame,
    };
}

pub fn deinit(self: *Self) void {
    self.frame.deinit();
    self.packet.deinit();
    self.audio_decoder.deinit();
    self.video_decoder.deinit();
    self.demuxer.deinit();
}

fn drain(self: *Self) !?Decoder.Frame {
    if (try self.video_decoder.pull(&self.frame))
        return self.frame;

    if (try self.audio_decoder.pull(&self.frame))
        return self.frame;

    return null;
}

fn fetch(self: *Self) !bool {
    if (self.is_flushed) return false;

    if (!self.is_pending_packet) {
        if (!try self.demuxer.next(&self.packet)) {
            try self.video_decoder.flush();
            try self.audio_decoder.flush();
            self.is_flushed = true;
            return false;
        }
        self.is_pending_packet = true;
    }
    return true;
}

fn feed(self: *Self) !void {
    const decoder = if (self.packet.stream_index() == self.video_stream.index())
        &self.video_decoder
    else if (self.packet.stream_index() == self.audio_stream.index())
        &self.audio_decoder
    else {
        self.packet.unref();
        self.is_pending_packet = false;
        return;
    };

    if (try decoder.push(self.packet)) {
        self.packet.unref();
        self.is_pending_packet = false;
    }
}

pub fn next(self: *Self) !?Decoder.Frame {
    while (true) {
        if (try self.drain()) |frame|
            return frame;
        if (!try self.fetch())
            return try self.drain();
        try self.feed();
    }
}

pub fn dimensions(self: *Self) [2]i32 {
    return .{ self.video_decoder.ptr.width, self.video_decoder.ptr.height };
}
