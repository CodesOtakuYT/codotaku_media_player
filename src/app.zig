const platform = @import("platform");
const Media = @import("media").Media;

pub const Config = struct {
    title: [:0]const u8,
    width: i32,
    height: i32,
    is_resizable: bool,
    url: [:0]const u8,
};
const Self = @This();

window: platform.Window,
media: Media,
texture: platform.Texture,
is_running: bool = true,

pub fn init(config: Config) !Self {
    try platform.init();
    errdefer platform.deinit();

    var window = try platform.Window.init(
        config.title,
        config.width,
        config.height,
        config.is_resizable,
    );
    errdefer window.deinit();

    var media = try Media.init(config.url);
    errdefer media.deinit();

    var texture = try platform.Texture.init(&window, media.dimensions());
    errdefer texture.deinit();

    try window.show();
    return .{
        .window = window,
        .media = media,
        .texture = texture,
    };
}

pub fn deinit(self: *Self) void {
    self.texture.deinit();
    self.media.deinit();
    self.window.deinit();
    platform.deinit();
}

pub fn update(self: *Self) !void {
    if (try self.media.next()) |frame| {
        if (frame.isVideo())
            try self.texture.updateYuv(frame.yuvData(), frame.stride());
    } else {
        self.is_running = false;
    }
}

pub fn render(self: *Self) !void {
    try self.window.clear(.{
        .r = 0,
        .g = 0,
        .b = 0,
        .a = 255,
    });
    try self.texture.render();
    try self.window.present();
}

pub fn handle_event(self: *Self, event: platform.Event) !void {
    switch (event) {
        .quit => self.is_running = false,
        else => {},
    }
}

pub fn run(self: *Self) !void {
    while (self.is_running) {
        while (platform.Event.poll()) |event| try self.handle_event(event);
        try self.update();
        try self.render();
    }
}
