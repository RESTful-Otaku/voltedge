const std = @import("std");

const log = std.log.scoped(.main);

const Config = struct {
    port: u16 = 9091,
    tick_rate_ms: u32 = 100,
    max_simulations: u32 = 10,
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

    log.info("Starting VoltEdge Simulation Engine", .{});
    log.info("Port: {}, Tick Rate: {}ms, Max Simulations: {}", .{ 
        config.port, 
        config.tick_rate_ms, 
        config.max_simulations 
    });

    // Create a simple test simulation
    try runSimpleSimulation(config);

    log.info("Simulation completed successfully", .{});
}

fn runSimpleSimulation(config: Config) !void {
    log.info("Starting simple grid simulation", .{});
    
    // Simulate a simple grid with 3 power plants
    const power_plants = [_]struct {
        name: []const u8,
        capacity_mw: f64,
        current_output_mw: f64,
        efficiency: f64,
    }{
        .{ .name = "Coal Plant Alpha", .capacity_mw = 500.0, .current_output_mw = 300.0, .efficiency = 0.85 },
        .{ .name = "Wind Farm Beta", .capacity_mw = 200.0, .current_output_mw = 150.0, .efficiency = 0.95 },
        .{ .name = "Solar Park Gamma", .capacity_mw = 150.0, .current_output_mw = 100.0, .efficiency = 0.90 },
    };
    
    var total_generation: f64 = 0.0;
    var total_consumption: f64 = 400.0; // Base load
    var grid_frequency: f64 = 50.0;
    
    // Run simulation for 100 ticks
    var tick_count: u32 = 0;
    while (tick_count < 100) {
        // Calculate total generation
        total_generation = 0.0;
        for (power_plants) |plant| {
            total_generation += plant.current_output_mw;
        }
        
        // Add some variation to consumption
        total_consumption = 400.0 + (@as(f64, @floatFromInt(tick_count % 24)) * 10.0);
        
        // Calculate frequency deviation
        const power_balance = total_generation - total_consumption;
        const frequency_deviation = power_balance / (total_generation + 1.0);
        grid_frequency = 50.0 + (frequency_deviation * 0.1);
        
        // Clamp frequency to realistic bounds
        grid_frequency = @max(45.0, @min(55.0, grid_frequency));
        
        log.info("Tick {}: Generation={:.1}MW, Consumption={:.1}MW, Frequency={:.2}Hz", .{
            tick_count,
            total_generation,
            total_consumption,
            grid_frequency
        });
        
        // Simulate some events
        if (tick_count == 25) {
            log.warn("Simulating wind farm output reduction due to low wind", .{});
        } else if (tick_count == 50) {
            log.warn("Simulating solar park peak output during midday", .{});
        } else if (tick_count == 75) {
            log.warn("Simulating coal plant maintenance shutdown", .{});
        }
        
        tick_count += 1;
        std.time.sleep(config.tick_rate_ms * std.time.ns_per_ms);
    }
    
    log.info("Simple simulation completed successfully", .{});
}

fn printUsage() void {
    const usage = 
        \\VoltEdge Simulation Engine (Simple Version)
        \\
        \\Usage: voltedge-sim [OPTIONS]
        \\
        \\Options:
        \\  --port PORT           Simulation server port (default: 9091)
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

