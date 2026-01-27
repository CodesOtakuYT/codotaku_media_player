pub fn checkFF(ret: i32) !void {
    if (ret < 0) return error.AVError;
}
