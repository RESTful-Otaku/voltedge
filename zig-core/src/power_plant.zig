const std = @import("std");
const TransmissionLine = @import("transmission.zig").TransmissionLine;

const log = std.log.scoped(.power_plant);

pub const PlantType = enum {
    coal,
    gas,
    nuclear,
    hydro,
    wind,
    solar,
    battery_storage,
    geothermal,
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

pub const Location = struct {
    x: f64,
    y: f64,
    name: []const u8,
};

pub const OperatingState = enum {
    online,
    offline,
    maintenance,
    fault,
    startup,
    shutdown,
};

pub const PowerPlant = struct {
    allocator: std.mem.Allocator,
    config: PowerPlantConfig,
    state: OperatingState,
    current_output_mw: f64,
    target_output_mw: f64,
    ramp_rate_mw_per_min: f64,
    min_output_mw: f64,
    max_output_mw: f64,

    // Efficiency and performance
    efficiency: f64,
    heat_rate_btu_per_kwh: f64,
    co2_emissions_kg_per_mwh: f64,

    // Maintenance and reliability
    operational_hours: u64,
    maintenance_interval_hours: u64,
    next_maintenance_due: u64,
    failure_probability: f64,

    // Renewable-specific parameters
    renewable_capacity_factor: f64 = 1.0,
    weather_dependency: bool = false,
    storage_capacity_mwh: f64 = 0.0,
    current_storage_mwh: f64 = 0.0,

    pub fn init(allocator: std.mem.Allocator, config: PowerPlantConfig) !PowerPlant {
        log.info("Initializing {} power plant: {} ({} MW)", .{ @tagName(config.plant_type), config.name, config.max_capacity_mw });

        const self = PowerPlant{
            .allocator = allocator,
            .config = config,
            .state = if (config.is_operational) .online else .offline,
            .current_output_mw = config.current_output_mw,
            .target_output_mw = config.current_output_mw,
            .ramp_rate_mw_per_min = PowerPlant.calculateRampRate(config.plant_type, config.max_capacity_mw),
            .min_output_mw = PowerPlant.calculateMinOutput(config.plant_type, config.max_capacity_mw),
            .max_output_mw = config.max_capacity_mw,
            .efficiency = config.efficiency,
            .heat_rate_btu_per_kwh = PowerPlant.calculateHeatRate(config.plant_type),
            .co2_emissions_kg_per_mwh = PowerPlant.calculateCO2Emissions(config.plant_type),
            .operational_hours = 0,
            .maintenance_interval_hours = PowerPlant.getMaintenanceInterval(config.plant_type),
            .next_maintenance_due = PowerPlant.getMaintenanceInterval(config.plant_type),
            .failure_probability = PowerPlant.calculateFailureProbability(config.plant_type),
            .renewable_capacity_factor = PowerPlant.getCapacityFactor(config.plant_type),
            .weather_dependency = PowerPlant.isWeatherDependent(config.plant_type),
            .storage_capacity_mwh = if (config.plant_type == .battery_storage) config.max_capacity_mw * 4.0 else 0.0,
            .current_storage_mwh = if (config.plant_type == .battery_storage) config.max_capacity_mw * 2.0 else 0.0,
        };

        log.info("Power plant initialized successfully", .{});
        return self;
    }

    pub fn deinit(self: *PowerPlant) void {
        log.info("Deinitializing power plant: {}", .{self.config.name});
    }

    pub fn update(self: *PowerPlant, delta_time_seconds: f64) !void {
        // Update operational hours
        if (self.state == .online) {
            self.operational_hours += @intFromFloat(delta_time_seconds / 3600.0);
        }

        // Check for maintenance requirement
        if (self.operational_hours >= self.next_maintenance_due) {
            try self.scheduleMaintenance();
        }

        // Update output based on ramp rate
        try self.updateOutput(delta_time_seconds);

        // Check for random failures
        try self.checkForFailures();

        // Update renewable output based on weather/conditions
        if (self.weather_dependency) {
            try self.updateRenewableOutput();
        }
    }

    fn updateOutput(self: *PowerPlant, delta_time_seconds: f64) !void {
        const ramp_delta = self.ramp_rate_mw_per_min * (delta_time_seconds / 60.0);
        const output_difference = self.target_output_mw - self.current_output_mw;

        if (std.math.fabs(output_difference) <= ramp_delta) {
            // Can reach target in this time step
            self.current_output_mw = self.target_output_mw;
        } else {
            // Ramp towards target
            const ramp_direction = if (output_difference > 0) 1.0 else -1.0;
            self.current_output_mw += ramp_direction * ramp_delta;
        }

        // Ensure output stays within bounds
        self.current_output_mw = @max(self.min_output_mw, @min(self.max_output_mw, self.current_output_mw));
    }

    fn updateRenewableOutput(self: *PowerPlant) !void {
        switch (self.config.plant_type) {
            .wind => {
                // Simplified wind model - varies throughout the day
                const time_of_day = @as(f64, @floatFromInt(std.time.timestamp() % 86400)) / 86400.0;
                const wind_factor = 0.5 + 0.5 * @sin(time_of_day * 2.0 * std.math.pi + std.math.pi / 4.0);
                self.target_output_mw = self.max_output_mw * wind_factor * self.renewable_capacity_factor;
            },
            .solar => {
                // Simplified solar model - peak during midday
                const time_of_day = @as(f64, @floatFromInt(std.time.timestamp() % 86400)) / 86400.0;
                const solar_factor = if (time_of_day >= 0.25 and time_of_day <= 0.75)
                    @sin((time_of_day - 0.25) * 2.0 * std.math.pi / 0.5)
                else
                    0.0;
                self.target_output_mw = self.max_output_mw * solar_factor * self.renewable_capacity_factor;
            },
            .hydro => {
                // Hydro is more stable but varies with season
                const seasonal_factor = 0.8 + 0.2 * @sin(@as(f64, @floatFromInt(std.time.timestamp() / 86400)) / 365.25 * 2.0 * std.math.pi);
                self.target_output_mw = self.max_output_mw * seasonal_factor * self.renewable_capacity_factor;
            },
            else => {
                // Non-renewable plants maintain target set by grid operator
            },
        }
    }

    fn checkForFailures(self: *PowerPlant) !void {
        if (self.state != .online) return;

        // Calculate failure probability based on operational hours and plant type
        const failure_prob = self.failure_probability * (1.0 + @as(f64, @floatFromInt(self.operational_hours)) / 8760.0);

        // Simple random failure check
        const random_value = @as(f64, @floatFromInt(std.hash_map.getAutoHashFn(u64, std.HashMap(u32, PowerPlant, std.HashMap(u32, PowerPlant).Context, std.hash_map.default_max_load_percentage).Context).hash(@intCast(std.time.timestamp())))) / @as(f64, @floatFromInt(std.math.maxInt(u64)));

        if (random_value < failure_prob) {
            try self.triggerFailure();
        }
    }

    fn triggerFailure(self: *PowerPlant) !void {
        log.warn("Power plant {} experienced a failure", .{self.config.name});
        self.state = .fault;
        self.current_output_mw = 0.0;
        self.target_output_mw = 0.0;
    }

    fn scheduleMaintenance(self: *PowerPlant) !void {
        log.info("Scheduling maintenance for power plant: {}", .{self.config.name});
        self.state = .maintenance;
        self.next_maintenance_due = self.operational_hours + self.maintenance_interval_hours;
    }

    pub fn setOutput(self: *PowerPlant, target_mw: f64) !void {
        if (self.state != .online) {
            log.debug("Cannot set output for plant {} - not online (state: {})", .{ self.config.name, @tagName(self.state) });
            return;
        }

        // Clamp target to valid range
        const clamped_target = @max(self.min_output_mw, @min(self.max_output_mw, target_mw));
        self.target_output_mw = clamped_target;

        log.debug("Set target output for {} to {} MW", .{ self.config.name, clamped_target });
    }

    pub fn injectFailure(self: *PowerPlant, failure_type: @import("simulator.zig").FailureType) !void {
        log.info("Injecting {} failure into power plant: {}", .{ @tagName(failure_type), self.config.name });

        switch (failure_type) {
            .power_plant_outage => {
                try self.triggerFailure();
            },
            .cyber_attack => {
                // Simulate cyber attack - random output fluctuations
                self.state = .fault;
                self.target_output_mw = self.max_output_mw * 0.1; // Reduced output
            },
            .natural_disaster => {
                // Natural disaster - complete shutdown
                self.state = .offline;
                self.current_output_mw = 0.0;
                self.target_output_mw = 0.0;
            },
            else => {
                log.warn("Unsupported failure type for power plant: {}", .{@tagName(failure_type)});
            },
        }
    }

    pub fn getCurrentOutput(self: PowerPlant) f64 {
        return self.current_output_mw;
    }

    pub fn getMaxOutput(self: PowerPlant) f64 {
        return self.max_output_mw;
    }

    pub fn getMinOutput(self: PowerPlant) f64 {
        return self.min_output_mw;
    }

    pub fn isOperational(self: PowerPlant) bool {
        return self.state == .online;
    }

    pub fn getPlantType(self: PowerPlant) PlantType {
        return self.config.plant_type;
    }

    pub fn getEfficiency(self: PowerPlant) f64 {
        return self.efficiency;
    }

    pub fn getCO2Emissions(self: PowerPlant) f64 {
        return self.co2_emissions_kg_per_mwh * self.current_output_mw;
    }

    // Static helper functions for plant characteristics
    fn calculateRampRate(plant_type: PlantType, capacity_mw: f64) f64 {
        return switch (plant_type) {
            .gas => capacity_mw * 0.1, // 10% per minute
            .hydro => capacity_mw * 0.5, // 50% per minute
            .wind, .solar => capacity_mw * 1.0, // 100% per minute
            .battery_storage => capacity_mw * 2.0, // 200% per minute
            .coal => capacity_mw * 0.05, // 5% per minute
            .nuclear => capacity_mw * 0.02, // 2% per minute
            .geothermal => capacity_mw * 0.2, // 20% per minute
        };
    }

    fn calculateMinOutput(plant_type: PlantType, capacity_mw: f64) f64 {
        return switch (plant_type) {
            .coal, .nuclear => capacity_mw * 0.3, // 30% minimum
            .gas => capacity_mw * 0.2, // 20% minimum
            .hydro, .battery_storage => 0.0, // Can go to zero
            .wind, .solar => 0.0, // Can go to zero
            .geothermal => capacity_mw * 0.1, // 10% minimum
        };
    }

    fn calculateHeatRate(plant_type: PlantType) f64 {
        return switch (plant_type) {
            .coal => 10.5, // 10,500 BTU/kWh
            .gas => 7.5, // 7,500 BTU/kWh
            .nuclear => 10.4, // 10,400 BTU/kWh
            .hydro => 0.0, // No heat input
            .wind => 0.0, // No heat input
            .solar => 0.0, // No heat input
            .battery_storage => 0.0, // No heat input
            .geothermal => 8.0, // 8,000 BTU/kWh
        };
    }

    fn calculateCO2Emissions(plant_type: PlantType) f64 {
        return switch (plant_type) {
            .coal => 820.0, // kg CO2/MWh
            .gas => 490.0, // kg CO2/MWh
            .nuclear => 12.0, // kg CO2/MWh
            .hydro => 24.0, // kg CO2/MWh
            .wind => 11.0, // kg CO2/MWh
            .solar => 41.0, // kg CO2/MWh
            .battery_storage => 100.0, // kg CO2/MWh (depends on charging source)
            .geothermal => 91.0, // kg CO2/MWh
        };
    }

    fn getMaintenanceInterval(plant_type: PlantType) u64 {
        return switch (plant_type) {
            .coal => 8760, // 1 year
            .gas => 4380, // 6 months
            .nuclear => 17520, // 2 years
            .hydro => 8760, // 1 year
            .wind => 2190, // 3 months
            .solar => 4380, // 6 months
            .battery_storage => 2190, // 3 months
            .geothermal => 8760, // 1 year
        };
    }

    fn calculateFailureProbability(plant_type: PlantType) f64 {
        return switch (plant_type) {
            .coal => 0.05, // 5% per year
            .gas => 0.08, // 8% per year
            .nuclear => 0.02, // 2% per year
            .hydro => 0.03, // 3% per year
            .wind => 0.12, // 12% per year
            .solar => 0.10, // 10% per year
            .battery_storage => 0.15, // 15% per year
            .geothermal => 0.04, // 4% per year
        };
    }

    fn getCapacityFactor(plant_type: PlantType) f64 {
        return switch (plant_type) {
            .coal => 0.85,
            .gas => 0.50,
            .nuclear => 0.92,
            .hydro => 0.40,
            .wind => 0.35,
            .solar => 0.25,
            .battery_storage => 0.90,
            .geothermal => 0.80,
        };
    }

    fn isWeatherDependent(plant_type: PlantType) bool {
        return switch (plant_type) {
            .wind, .solar => true,
            else => false,
        };
    }
};
