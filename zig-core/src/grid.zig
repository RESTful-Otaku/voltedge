const std = @import("std");
const PowerPlant = @import("power_plant.zig").PowerPlant;
const PlantType = @import("power_plant.zig").PlantType;
const TransmissionLine = @import("transmission.zig").TransmissionLine;

const log = std.log.scoped(.grid);

pub const GridState = struct {
    total_generation: f64,
    total_consumption: f64,
    frequency: f64,
    voltage_levels: []f64,
    active_failures: []u32,
    timestamp: i64,
};

pub const GridConfig = struct {
    power_plants: []PowerPlantConfig,
    transmission_lines: []TransmissionLineConfig,
    base_frequency: f64 = 50.0, // Hz
    base_voltage: f64 = 230.0,  // kV
    load_profile: LoadProfile,
};

pub const PowerPlantConfig = struct {
    id: u32,
    name: []const u8,
    plant_type: PlantType,
    max_capacity_mw: f64,
    current_output_mw: f64 = 0.0,
    efficiency: f64 = 0.85,
    location: Location,
    is_operational: bool = true,
};

pub const TransmissionLineConfig = struct {
    id: u32,
    from_node: u32,
    to_node: u32,
    capacity_mw: f64,
    length_km: f64,
    resistance_per_km: f64 = 0.1,
    reactance_per_km: f64 = 0.4,
    is_operational: bool = true,
};

pub const LoadProfile = struct {
    base_load_mw: f64,
    peak_multiplier: f64 = 1.5,
    daily_variation: f64 = 0.3,
    random_variation: f64 = 0.1,
};

pub const Location = struct {
    x: f64,
    y: f64,
    name: []const u8,
};

pub const Grid = struct {
    allocator: std.mem.Allocator,
    config: GridConfig,
    power_plants: std.HashMap(u32, PowerPlant, std.HashMap(u32, PowerPlant).Context, std.hash_map.default_max_load_percentage),
    transmission_lines: std.HashMap(u32, TransmissionLine, std.HashMap(u32, TransmissionLine).Context, std.hash_map.default_max_load_percentage),
    current_state: GridState,
    simulation_time: i64,
    tick_count: u64,
    
    // Performance optimization
    generation_cache: f64 = 0.0,
    consumption_cache: f64 = 0.0,
    cache_valid: bool = false,
    
    pub fn init(allocator: std.mem.Allocator, config: GridConfig) !Grid {
        log.info("Initializing grid with {} power plants and {} transmission lines", .{ 
            config.power_plants.len, 
            config.transmission_lines.len 
        });
        
        var self = Grid{
            .allocator = allocator,
            .config = config,
            .power_plants = std.HashMap(u32, PowerPlant, std.HashMap(u32, PowerPlant).Context, std.hash_map.default_max_load_percentage).init(allocator),
            .transmission_lines = std.HashMap(u32, TransmissionLine, std.HashMap(u32, TransmissionLine).Context, std.hash_map.default_max_load_percentage).init(allocator),
            .current_state = GridState{
                .total_generation = 0.0,
                .total_consumption = 0.0,
                .frequency = config.base_frequency,
                .voltage_levels = try allocator.alloc(f64, 0),
                .active_failures = try allocator.alloc(u32, 0),
                .timestamp = std.time.timestamp(),
            },
            .simulation_time = std.time.timestamp(),
            .tick_count = 0,
            .cache_valid = false,
        };
        
        // Initialize power plants
        for (config.power_plants) |plant_config| {
            const plant = try PowerPlant.init(allocator, plant_config);
            try self.power_plants.put(plant_config.id, plant);
        }
        
        // Initialize transmission lines
        for (config.transmission_lines) |line_config| {
            const line = try TransmissionLine.init(allocator, line_config);
            try self.transmission_lines.put(line_config.id, line);
        }
        
        // Calculate initial state
        try self.updateGridState();
        
        log.info("Grid initialized successfully", .{});
        return self;
    }
    
    pub fn deinit(self: *Grid) void {
        log.info("Deinitializing grid", .{});
        
        // Clean up power plants
        var plant_iterator = self.power_plants.iterator();
        while (plant_iterator.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.power_plants.deinit();
        
        // Clean up transmission lines
        var line_iterator = self.transmission_lines.iterator();
        while (line_iterator.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.transmission_lines.deinit();
        
        self.allocator.free(self.current_state.voltage_levels);
        self.allocator.free(self.current_state.active_failures);
        
        log.info("Grid deinitialized", .{});
    }
    
    pub fn simulateTick(self: *Grid) !GridState {
        self.tick_count += 1;
        self.simulation_time = std.time.timestamp();
        
        // Update power plant outputs based on demand and constraints
        try self.updatePowerPlantOutputs();
        
        // Calculate transmission losses and line flows
        try self.calculateTransmissionFlows();
        
        // Update grid frequency based on generation/consumption balance
        try self.updateGridFrequency();
        
        // Update voltage levels
        try self.updateVoltageLevels();
        
        // Check for cascading failures
        try self.checkCascadingFailures();
        
        // Update grid state
        try self.updateGridState();
        
        return self.current_state;
    }
    
    fn updatePowerPlantOutputs(self: *Grid) !void {
        const current_demand = self.calculateCurrentDemand();
        const available_capacity = self.calculateAvailableCapacity();
        
        // Simple load-following algorithm
        const target_generation = @min(current_demand, available_capacity);
        
        // Distribute generation across operational plants
        var remaining_demand = target_generation;
        var plant_iterator = self.power_plants.iterator();
        
        while (plant_iterator.next()) |entry| {
            const plant = entry.value_ptr;
            if (!plant.isOperational()) continue;
            
            const max_output = plant.getMaxOutput();
            const desired_output = @min(remaining_demand, max_output);
            
            try plant.setOutput(desired_output);
            remaining_demand -= desired_output;
            
            if (remaining_demand <= 0) break;
        }
        
        // Log if demand cannot be met
        if (remaining_demand > 0) {
            log.warn("Insufficient generation capacity: {} MW shortfall", .{remaining_demand});
        }
    }
    
    fn calculateCurrentDemand(self: *Grid) f64 {
        const base_demand = self.config.load_profile.base_load_mw;
        
        // Add daily variation (simplified sine wave)
        const time_of_day = (@as(f64, @floatFromInt(self.simulation_time % 86400)) / 86400.0) * 2.0 * std.math.pi;
        const daily_variation = base_demand * self.config.load_profile.daily_variation * @sin(time_of_day);
        
        // Add random variation (simplified)
        const random_factor = 1.0 + (self.config.load_profile.random_variation * 0.1);
        
        return base_demand + daily_variation * random_factor;
    }
    
    fn calculateAvailableCapacity(self: *Grid) f64 {
        var total_capacity: f64 = 0.0;
        
        var plant_iterator = self.power_plants.iterator();
        while (plant_iterator.next()) |entry| {
            const plant = entry.value_ptr;
            if (plant.isOperational()) {
                total_capacity += plant.getMaxOutput();
            }
        }
        
        return total_capacity;
    }
    
    fn calculateTransmissionFlows(self: *Grid) !void {
        // Simplified transmission flow calculation
        // In a real implementation, this would solve power flow equations
        
        var line_iterator = self.transmission_lines.iterator();
        while (line_iterator.next()) |entry| {
            const line = entry.value_ptr;
            if (!line.isOperational()) continue;
            
            // Calculate flow based on generation and demand at connected nodes
            const flow = line.calculateFlow(self);
            try line.setFlow(flow);
        }
    }
    
    fn updateGridFrequency(self: *Grid) !void {
        const generation = self.current_state.total_generation;
        const consumption = self.current_state.total_consumption;
        
        // Simple frequency regulation model
        const power_balance = generation - consumption;
        const frequency_deviation = power_balance / (generation + 1.0); // Avoid division by zero
        
        // Update frequency with damping
        const damping_factor = 0.1;
        self.current_state.frequency = self.config.base_frequency + (frequency_deviation * damping_factor);
        
        // Clamp frequency to realistic bounds
        self.current_state.frequency = @max(45.0, @min(55.0, self.current_state.frequency));
    }
    
    fn updateVoltageLevels(self: *Grid) !void {
        // Simplified voltage calculation
        // In reality, this would involve solving complex power flow equations
        
        const num_nodes = self.power_plants.count() + self.transmission_lines.count();
        
        // Reallocate voltage array if needed
        if (self.current_state.voltage_levels.len != num_nodes) {
            self.allocator.free(self.current_state.voltage_levels);
            self.current_state.voltage_levels = try self.allocator.alloc(f64, num_nodes);
        }
        
        // Set base voltage for all nodes (simplified)
        for (self.current_state.voltage_levels, 0..) |*voltage, i| {
            voltage.* = self.config.base_voltage * (1.0 + 0.05 * @sin(@as(f64, @floatFromInt(i)) * 0.1));
        }
    }
    
    fn checkCascadingFailures(self: *Grid) !void {
        // Check for cascading failures based on frequency and voltage
        if (self.current_state.frequency < 48.0 or self.current_state.frequency > 52.0) {
            log.warn("Grid frequency outside normal range: {} Hz", .{self.current_state.frequency});
            
            // Trigger protective shutdowns if frequency is too extreme
            if (self.current_state.frequency < 47.0 or self.current_state.frequency > 53.0) {
                try self.triggerProtectiveShutdowns();
            }
        }
    }
    
    fn triggerProtectiveShutdowns(self: *Grid) !void {
        log.err("Triggering protective shutdowns due to extreme frequency", .{});
        
        // Shutdown non-essential loads
        var plant_iterator = self.power_plants.iterator();
        while (plant_iterator.next()) |entry| {
            const plant = entry.value_ptr;
            if (plant.getPlantType() == .renewable) {
                // Renewable sources are typically first to be disconnected
                try plant.setOutput(0.0);
            }
        }
    }
    
    fn updateGridState(self: *Grid) !void {
        // Update total generation
        var total_generation: f64 = 0.0;
        var plant_iterator = self.power_plants.iterator();
        while (plant_iterator.next()) |entry| {
            const plant = entry.value_ptr;
            if (plant.isOperational()) {
                total_generation += plant.getCurrentOutput();
            }
        }
        self.current_state.total_generation = total_generation;
        
        // Update total consumption
        self.current_state.total_consumption = self.calculateCurrentDemand();
        
        // Update timestamp
        self.current_state.timestamp = self.simulation_time;
        
        // Update failure list
        try self.updateActiveFailures();
        
        self.cache_valid = true;
    }
    
    fn updateActiveFailures(self: *Grid) !void {
        var failures = std.ArrayList(u32).init(self.allocator);
        defer failures.deinit();
        
        // Check power plant failures
        var plant_iterator = self.power_plants.iterator();
        while (plant_iterator.next()) |entry| {
            const plant = entry.value_ptr;
            if (!plant.isOperational()) {
                try failures.append(entry.key_ptr.*);
            }
        }
        
        // Check transmission line failures
        var line_iterator = self.transmission_lines.iterator();
        while (line_iterator.next()) |entry| {
            const line = entry.value_ptr;
            if (!line.isOperational()) {
                try failures.append(entry.key_ptr.*);
            }
        }
        
        // Update failure array
        self.allocator.free(self.current_state.active_failures);
        self.current_state.active_failures = try failures.toOwnedSlice();
    }
    
    pub fn injectFailure(self: *Grid, component_id: u32, failure_type: @import("simulator.zig").FailureType) !void {
        log.info("Injecting failure: {} into component {}", .{ @tagName(failure_type), component_id });
        
        // Try to inject into power plant
        if (self.power_plants.getPtr(component_id)) |plant| {
            try plant.injectFailure(failure_type);
            return;
        }
        
        // Try to inject into transmission line
        if (self.transmission_lines.getPtr(component_id)) |line| {
            try line.injectFailure(failure_type);
            return;
        }
        
        log.warn("Component {} not found for failure injection", .{component_id});
    }
    
    pub fn getState(self: *Grid) GridState {
        return self.current_state;
    }
    
    pub fn getPowerPlant(self: *Grid, id: u32) ?*PowerPlant {
        return self.power_plants.getPtr(id);
    }
    
    pub fn getTransmissionLine(self: *Grid, id: u32) ?*TransmissionLine {
        return self.transmission_lines.getPtr(id);
    }
};
