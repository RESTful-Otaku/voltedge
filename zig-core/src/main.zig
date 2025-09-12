const std = @import("std");
const Simulator = @import("simulator.zig").Simulator;

const log = std.log.scoped(.main);

const Config = struct {
    port: u16 = 9091,
    tick_rate_ms: u32 = 100,
    max_simulations: u32 = 10,
    log_level: std.log.Level = .info,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    var config = Config{};
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next(); // Skip program name

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--port")) {
            if (args.next()) |port_str| {
                config.port = std.fmt.parseInt(u16, port_str, 10) catch {
                    log.err("Invalid port: {s}", .{port_str});
                    return;
                };
            }
        } else if (std.mem.eql(u8, arg, "--tick-rate")) {
            if (args.next()) |rate_str| {
                config.tick_rate_ms = std.fmt.parseInt(u32, rate_str, 10) catch {
                    log.err("Invalid tick rate: {s}", .{rate_str});
                    return;
                };
            }
        } else if (std.mem.eql(u8, arg, "--max-sims")) {
            if (args.next()) |max_str| {
                config.max_simulations = std.fmt.parseInt(u32, max_str, 10) catch {
                    log.err("Invalid max simulations: {s}", .{max_str});
                    return;
                };
            }
        } else if (std.mem.eql(u8, arg, "--help")) {
            printUsage();
            return;
        }
    }

    // Log level is set via build configuration in Zig
    _ = config.log_level;

    log.info("Starting VoltEdge Simulation Engine", .{});
    log.info("Port: {}, Tick Rate: {}ms, Max Simulations: {}", .{ config.port, config.tick_rate_ms, config.max_simulations });

    // Create the simulation engine
    var simulator = try Simulator.init(allocator, config);
    defer simulator.deinit();

    // Start the simulation server (simplified for testing)
    log.info("Starting simulation server on port {}", .{config.port});
    try simulator.startServer(config.port);

    // Keep the main thread alive
    std.event.Loop.instance.?.run();
}

fn printUsage() void {
    const usage =
        \\VoltEdge Simulation Engine
        \\
        \\Usage: voltedge-sim [OPTIONS]
        \\
        \\Options:
        \\  --port PORT           gRPC server port (default: 9091)
        \\  --tick-rate MS        Simulation tick rate in milliseconds (default: 100)
        \\  --max-sims COUNT      Maximum concurrent simulations (default: 10)
        \\  --help               Show this help message
        \\
        \\Examples:
        \\  voltedge-sim --port 9092 --tick-rate 50
        \\  voltedge-sim --max-sims 20
        \\
    ;
    std.debug.print("{s}", .{usage});
}
