pub fn checkSDL(ret: bool) !void {
    if (!ret) {
        return error.SDLError;
    }
}
