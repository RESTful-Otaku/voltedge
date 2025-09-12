const std = @import("std");
const Grid = @import("grid.zig").Grid;
const PowerPlant = @import("power_plant.zig").PowerPlant;
const TransmissionLine = @import("transmission.zig").TransmissionLine;

const log = std.log.scoped(.simulator);

pub const SimulationState = enum {
    idle,
    running,
    paused,
    failed,
};

pub const SimulationConfig = struct {
    tick_rate_ms: u32,
    max_simulations: u32,
};

pub const SimulationResult = struct {
    id: u32,
    timestamp: i64,
    total_generation: f64,
    total_consumption: f64,
    grid_frequency: f64,
    voltage_levels: []f64,
    active_failures: []u32,
    performance_metrics: PerformanceMetrics,
};

pub const PerformanceMetrics = struct {
    events_per_second: u64,
    memory_usage_mb: u64,
    cpu_usage_percent: f64,
    simulation_lag_ms: u64,
};

pub const Simulator = struct {
    allocator: std.mem.Allocator,
    config: SimulationConfig,
    state: SimulationState,
    simulations: std.HashMap(u32, Grid, std.HashMap(u32, Grid).Context, std.hash_map.default_max_load_percentage),
    next_simulation_id: u32,
    tick_timer: ?std.time.Timer,
    server: ?u32, // Simplified server handle
    
    // Performance tracking
    events_processed: u64,
    last_performance_update: i64,
    
    pub fn init(allocator: std.mem.Allocator, config: SimulationConfig) !Simulator {
        log.info("Initializing VoltEdge Simulator", .{});
        
        var self = Simulator{
            .allocator = allocator,
            .config = config,
            .state = .idle,
            .simulations = std.HashMap(u32, Grid, std.HashMap(u32, Grid).Context, std.hash_map.default_max_load_percentage).init(allocator),
            .next_simulation_id = 1,
            .tick_timer = null,
            .server = null,
            .events_processed = 0,
            .last_performance_update = std.time.timestamp(),
        };
        
        // Initialize performance timer
        self.tick_timer = std.time.Timer.start() catch |err| {
            log.err("Failed to initialize timer: {}", .{err});
            return err;
        };
        
        log.info("Simulator initialized successfully", .{});
        return self;
    }
    
    pub fn deinit(self: *Simulator) void {
        log.info("Shutting down VoltEdge Simulator", .{});
        
        // Clean up simulations
        var iterator = self.simulations.iterator();
        while (iterator.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.simulations.deinit();
        
        log.info("Simulator shutdown complete", .{});
    }
    
    pub fn startServer(self: *Simulator, port: u16) !void {
        log.info("Starting simulation server on port {}", .{port});
        
        // Simplified server initialization for testing
        // In production, this would be a proper gRPC server
        self.server = port;
        self.state = .running;
        
        log.info("Simulation server started successfully", .{});
        
        // Start a simple simulation loop for testing
        try self.startSimulationLoop();
    }
    
    fn startSimulationLoop(self: *Simulator) !void {
        log.info("Starting simulation loop", .{});
        
        // Create a simple test simulation
        const test_config = createTestGridConfig();
        const simulation_id = try self.createSimulation(test_config);
        
        // Run simulation for a few ticks
        var tick_count: u32 = 0;
        while (tick_count < 100) {
            const result = try self.runSimulationTick(simulation_id);
            
            log.info("Tick {}: Generation={:.1}MW, Consumption={:.1}MW, Frequency={:.2}Hz", .{
                tick_count,
                result.total_generation,
                result.total_consumption,
                result.grid_frequency
            });
            
            tick_count += 1;
            std.time.sleep(100 * std.time.ns_per_ms); // 100ms tick rate
        }
        
        log.info("Test simulation completed", .{});
    }
    
    fn createTestGridConfig() Grid.GridConfig {
        return Grid.GridConfig{
            .power_plants = [_]Grid.PowerPlantConfig{
                Grid.PowerPlantConfig{
                    .id = 1,
                    .name = "Coal Plant Alpha",
                    .plant_type = .coal,
                    .max_capacity_mw = 500.0,
                    .current_output_mw = 300.0,
                    .efficiency = 0.85,
                    .location = Grid.Location{ .x = 0.2, .y = 0.3, .name = "North Region" },
                    .is_operational = true,
                },
                Grid.PowerPlantConfig{
                    .id = 2,
                    .name = "Wind Farm Beta",
                    .plant_type = .wind,
                    .max_capacity_mw = 200.0,
                    .current_output_mw = 150.0,
                    .efficiency = 0.95,
                    .location = Grid.Location{ .x = 0.7, .y = 0.4, .name = "Coastal Region" },
                    .is_operational = true,
                },
                Grid.PowerPlantConfig{
                    .id = 3,
                    .name = "Solar Park Gamma",
                    .plant_type = .solar,
                    .max_capacity_mw = 150.0,
                    .current_output_mw = 100.0,
                    .efficiency = 0.90,
                    .location = Grid.Location{ .x = 0.5, .y = 0.6, .name = "Desert Region" },
                    .is_operational = true,
                },
            },
            .transmission_lines = [_]Grid.TransmissionLineConfig{
                Grid.TransmissionLineConfig{
                    .id = 1,
                    .from_node = 1,
                    .to_node = 2,
                    .capacity_mw = 300.0,
                    .length_km = 50.0,
                    .resistance_per_km = 0.1,
                    .reactance_per_km = 0.4,
                    .is_operational = true,
                },
                Grid.TransmissionLineConfig{
                    .id = 2,
                    .from_node = 2,
                    .to_node = 3,
                    .capacity_mw = 200.0,
                    .length_km = 30.0,
                    .resistance_per_km = 0.1,
                    .reactance_per_km = 0.4,
                    .is_operational = true,
                },
            },
            .base_frequency = 50.0,
            .base_voltage = 230.0,
            .load_profile = Grid.LoadProfile{
                .base_load_mw = 400.0,
                .peak_multiplier = 1.5,
                .daily_variation = 0.3,
                .random_variation = 0.1,
            },
        };
    }
    
    pub fn createSimulation(self: *Simulator, grid_config: Grid.GridConfig) !u32 {
        if (self.simulations.count() >= self.config.max_simulations) {
            log.warn("Maximum simulations reached: {}", .{self.config.max_simulations});
            return error.MaxSimulationsReached;
        }
        
        const simulation_id = self.next_simulation_id;
        self.next_simulation_id += 1;
        
        log.info("Creating simulation {} with {} power plants", .{ 
            simulation_id, 
            grid_config.power_plants.len 
        });
        
        const grid = try Grid.init(self.allocator, grid_config);
        try self.simulations.put(simulation_id, grid);
        
        log.info("Simulation {} created successfully", .{simulation_id});
        return simulation_id;
    }
    
    pub fn deleteSimulation(self: *Simulator, simulation_id: u32) !void {
        if (self.simulations.getPtr(simulation_id)) |grid| {
            grid.deinit();
            _ = self.simulations.remove(simulation_id);
            log.info("Simulation {} deleted", .{simulation_id});
        } else {
            log.warn("Simulation {} not found", .{simulation_id});
            return error.SimulationNotFound;
        }
    }
    
    pub fn runSimulationTick(self: *Simulator, simulation_id: u32) !SimulationResult {
        const grid = self.simulations.getPtr(simulation_id) orelse {
            return error.SimulationNotFound;
        };
        
        // Record start time for performance tracking
        const start_time = std.time.nanoTimestamp();
        
        // Run the simulation tick
        const grid_state = try grid.simulateTick();
        
        // Update performance metrics
        self.events_processed += 1;
        const end_time = std.time.nanoTimestamp();
        const tick_duration_ms = (end_time - start_time) / std.time.ns_per_ms;
        
        // Create result
        const result = SimulationResult{
            .id = simulation_id,
            .timestamp = std.time.timestamp(),
            .total_generation = grid_state.total_generation,
            .total_consumption = grid_state.total_consumption,
            .grid_frequency = grid_state.frequency,
            .voltage_levels = try self.allocator.dupe(f64, grid_state.voltage_levels),
            .active_failures = try self.allocator.dupe(u32, grid_state.active_failures),
            .performance_metrics = PerformanceMetrics{
                .events_per_second = self.calculateEventsPerSecond(),
                .memory_usage_mb = self.getMemoryUsage(),
                .cpu_usage_percent = 0.0, // TODO: Implement CPU monitoring
                .simulation_lag_ms = tick_duration_ms,
            },
        };
        
        // Log performance if tick took too long
        if (tick_duration_ms > 10) {
            log.warn("Slow simulation tick: {}ms for simulation {}", .{ 
                tick_duration_ms, 
                simulation_id 
            });
        }
        
        return result;
    }
    
    pub fn injectFailure(self: *Simulator, simulation_id: u32, component_id: u32, failure_type: FailureType) !void {
        const grid = self.simulations.getPtr(simulation_id) orelse {
            return error.SimulationNotFound;
        };
        
        log.info("Injecting {} failure into component {} in simulation {}", .{ 
            @tagName(failure_type), 
            component_id, 
            simulation_id 
        });
        
        try grid.injectFailure(component_id, failure_type);
    }
    
    pub fn getAllSimulations(self: *Simulator) []const u32 {
        var ids = self.allocator.alloc(u32, self.simulations.count()) catch return &.{};
        defer self.allocator.free(ids);
        
        var index: usize = 0;
        var iterator = self.simulations.iterator();
        while (iterator.next()) |entry| {
            ids[index] = entry.key_ptr.*;
            index += 1;
        }
        
        return ids;
    }
    
    fn calculateEventsPerSecond(self: *Simulator) u64 {
        const now = std.time.timestamp();
        const elapsed_seconds = @as(f64, @floatFromInt(now - self.last_performance_update));
        
        if (elapsed_seconds > 0) {
            const eps = @as(u64, @intFromFloat(@as(f64, @floatFromInt(self.events_processed)) / elapsed_seconds));
            self.events_processed = 0;
            self.last_performance_update = now;
            return eps;
        }
        
        return 0;
    }
    
    fn getMemoryUsage(_: *Simulator) u64 {
        // TODO: Implement actual memory usage tracking
        // This would typically use system calls to get process memory usage
        return 0;
    }
};

pub const FailureType = enum {
    power_plant_outage,
    transmission_line_fault,
    substation_failure,
    cascading_failure,
    cyber_attack,
    natural_disaster,
};