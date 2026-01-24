const platform = @import("platform");

pub const Config = struct {
    title: [:0]const u8,
    width: i32,
    height: i32,
    is_resizable: bool,
};

const Self = @This();

window: platform.Window,
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

    try window.show();
    return .{
        .window = window,
    };
}

pub fn deinit(self: *Self) void {
    self.window.deinit();
    platform.deinit();
}

pub fn update(self: *Self) !void {
    _ = self;
}

pub fn render(self: *Self) !void {
    try self.window.clear(.{
        .r = 255,
        .g = 0,
        .b = 0,
        .a = 255,
    });
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
