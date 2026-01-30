const App = @import("app.zig");
const std = @import("std");

pub fn main() !void {
    var gpa = @as(std.heap.DebugAllocator(.{}), .init);
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip();

    const url = args.next().?;

    var app = try App.init(.{
        .title = "Codotaku Media Player",
        .width = 800,
        .height = 600,
        .is_resizable = true,
        .url = url,
    });
    defer app.deinit();

    try app.run();
}
