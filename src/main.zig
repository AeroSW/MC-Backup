//! Application built to automate Minecraft Server Backup for myself.
//! 
//! Additional Technologies being used in project are the following:
//! - [NanaZip](https://apps.microsoft.com/detail/9n8g7tscl18r?hl=en-US&gl=US)
//! - [MCRCon](https://github.com/Tiiffi/mcrcon)

const std = @import("std");
const c = @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
});
const ctime = @cImport({
    @cInclude("time.h");
});
//const mc_rcon_name: []u16 = w("minecraft-rcon");
const mc_rcon_name     = "minecraft-rcon";
const mc_server_folder = "minecraft-server";

const backup_dir = "../Backups/zips/";
const backup_log = "../Backups/logs/";

const nanazip = "nanazipc";
const nanazip_pre_args = "a";
const nanazip_args = "-t7z ./ -x!Backups/* -x!mods/*";

const BackupPair: type = struct {
    timestamp: i32,
    name: []const u8
};

pub fn getEnvironmentVariable(mem_allocator: std.mem.Allocator, var_name: []const u8) ![]const u8 {
    const env_map = try std.process.getEnvMap(mem_allocator);
    const env = env_map.get(var_name) orelse "null";
    return env;
}

pub fn backupServer(arena_alloc: std.mem.Allocator) !void {
    var ts: ctime.time_t = undefined;
    _ = ctime.time(&ts);
    const time_info = ctime.localtime(&ts);
    const heap_alloc = std.heap.page_allocator;
    const dt_str = try std.fmt.allocPrint(arena_alloc, "{d}-{d}-{d}_{d}",
        .{time_info.tm_year, time_info.tm_mon, time_info.tm_mday, time_info.tm_hour});
    const backup_name = try std.mem.concat(arena_alloc, u8, .{
        backup_dir,
        dt_str,
        ".coolkids.mc-server-backup.7z"
    });
    const log_name = try std.mem.concat(arena_alloc, u8, .{
        backup_log,
        dt_str,
        ".coolkids.mc-server-backup.log"
    });
    const flags: std.fs.File.CreateFlags = .{.lock = true, .truncate = true, .exclusive = true, .read = false};
    const f = try std.fs.cwd().createFile(log_name, flags);
    defer f.close();
    const archival_process = std.process.Child.init(.{nanazip, nanazip_pre_args, backup_name, nanazip_args}, heap_alloc);
    archival_process.stdout = f;
    archival_process.spawn();
    archival_process.wait();
}

pub fn cleanupBackups(arena_alloc: std.mem.Allocator) !void {
    var backup = try std.fs.cwd().openDir(backup_dir, .{});
    defer backup.close();
    const iter: std.fs.Dir.Iterator = backup.iterate();
    var pair_list = std.ArrayList(BackupPair).init(arena_alloc);
    defer pair_list.deinit();
    while(try iter.next()) |itm| {
        if (itm.kind != std.fs.File.Kind.file) continue;
        var file = try std.fs.cwd().openFile(itm.name, .{});
        defer file.close();
        var md = try file.metadata();
        const entry: BackupPair = .{.timestamp = md.created(), .name = itm.name};
        pair_list.append(entry);
    }
    std.mem.sort(BackupPair, pair_list.items, {}, Comparitor);
    while(pair_list.items.len > 10) {
        _ = try pair_list.pop();
    }
}

pub fn Comparitor(_: void, itm_1: BackupPair, itm_2: BackupPair) bool {
    return itm_1.timestamp > itm_2.timestamp;
}

pub fn main() !void {
    var mem_buff: [2000]u8 = undefined;
    var fixed_buff = std.heap.FixedBufferAllocator.init(&mem_buff);
    const fixed_buff_alloc = fixed_buff.allocator();
    var arena_alloc = std.heap.ArenaAllocator.init(fixed_buff_alloc);
    defer arena_alloc.deinit();
    const alloc = arena_alloc.allocator();
    const mc_server_path = try getEnvironmentVariable(alloc, mc_server_folder);
    var cwd_dir = try std.fs.cwd().openDir(mc_server_path, .{});
    defer cwd_dir.close();
    try cwd_dir.setAsCwd();
    //const rcon_path = try getEnvironmentVariable(alloc, mc_rcon_name);
    // const cmds: [][]const u8 = .{
    //     "'say [WARNING] Server Backup Process will begin in 5 minutes.'",
    //     "'say [WARNING] Server Backup Process is starting NOW.'",
    //     "'save-off'",
    //     "'save-all'",
    //     "'save-on'",
    //     "'say [NOTICE] Server Backup Process is complete.'"
    // };
    
}

test "Sort Testing Fn" {
    var mem_buff: [2000]u8 = undefined;
    var fixed_buff = std.heap.FixedBufferAllocator.init(&mem_buff);
    const fixed_buff_alloc = fixed_buff.allocator();
    var arena_alloc = std.heap.ArenaAllocator.init(fixed_buff_alloc);
    defer arena_alloc.deinit();
    const alloc = arena_alloc.allocator();
    
    const item_1: BackupPair = .{ .timestamp = 12, .name = "Hello, World!" };
    const item_2: BackupPair = .{ .timestamp = 8, .name = "Aye" };
    const item_3: BackupPair = .{ .timestamp = 3, .name = "Tree" };
    const item_4: BackupPair = .{ .timestamp = 16, .name = "Aeline" };
    const item_5: BackupPair = .{ .timestamp = 2, .name = "Zwei" };
    var li = std.ArrayList(BackupPair).init(alloc);
    try li.append(item_1);
    try li.append(item_2);
    try li.append(item_3);
    try li.append(item_4);
    try li.append(item_5);
    var cx: usize = 0;
    
    std.mem.sort(BackupPair, li.items, {}, Comparitor);
    while (cx < li.items.len):(cx += 1) {
        std.debug.print("\n{s}", .{li.items[cx].name});
    }
    std.debug.print("\n",.{});
    try std.testing.expect(std.mem.eql(u8, item_5.name, li.items[4].name));
    try std.testing.expect(std.mem.eql(u8, item_3.name, li.items[3].name));
    try std.testing.expect(std.mem.eql(u8, item_2.name, li.items[2].name));
    try std.testing.expect(std.mem.eql(u8, item_1.name, li.items[1].name));
    try std.testing.expect(std.mem.eql(u8, item_4.name, li.items[0].name));
}
