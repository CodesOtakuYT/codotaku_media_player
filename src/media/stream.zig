const c = @import("c.zig").c;
const checkFF = @import("internal.zig").checkFF;

const Self = @This();
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

pub fn info(self: Self) Info {
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

pub fn index(self: Self) usize {
    return @intCast(self.ptr.index);
}

pub fn codec_parameters(self: Self) *c.AVCodecParameters {
    return self.ptr.codecpar;
}
