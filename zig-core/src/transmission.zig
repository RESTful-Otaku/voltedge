. s.onst std = @import("std");
const PowerPlant = @import("power_plant.zig").PowerPlant;

const log = std.log.scoped(.transmission);

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

pub const TransmissionLine = struct {
    allocator: std.mem.Allocator,
    config: TransmissionLineConfig,
    current_flow_mw: f64,
    voltage_from: f64,
    voltage_to: f64,
    power_loss_mw: f64,
    thermal_rating_mw: f64,
    current_rating_amps: f64,
    operational_hours: u64,
    failure_probability: f64,
    is_operational: bool,

    // Electrical parameters
    total_resistance: f64,
    total_reactance: f64,
    surge_impedance: f64,
    charging_current: f64,

    // Protection settings
    overcurrent_threshold_amps: f64,
    overvoltage_threshold_kv: f64,
    undervoltage_threshold_kv: f64,

    pub fn init(allocator: std.mem.Allocator, config: TransmissionLineConfig) !TransmissionLine {
        log.info("Initializing transmission line {}: {} MW, {} km", .{ config.id, config.capacity_mw, config.length_km });

        const total_resistance = config.resistance_per_km * config.length_km;
        const total_reactance = config.reactance_per_km * config.length_km;
        const surge_impedance = @sqrt(total_resistance * total_resistance + total_reactance * total_reactance);

        const self = TransmissionLine{
            .allocator = allocator,
            .config = config,
            .current_flow_mw = 0.0,
            .voltage_from = 230.0, // kV
            .voltage_to = 230.0, // kV
            .power_loss_mw = 0.0,
            .thermal_rating_mw = config.capacity_mw * 1.1, // 10% margin
            .current_rating_amps = config.capacity_mw * 1000.0 / (230.0 * @sqrt(3.0)), // Simplified
            .operational_hours = 0,
            .failure_probability = TransmissionLine.calculateFailureProbability(config.length_km),
            .is_operational = config.is_operational,
            .total_resistance = total_resistance,
            .total_reactance = total_reactance,
            .surge_impedance = surge_impedance,
            .charging_current = config.length_km * 0.001, // Simplified
            .overcurrent_threshold_amps = config.capacity_mw * 1000.0 / (230.0 * @sqrt(3.0)) * 1.2,
            .overvoltage_threshold_kv = 230.0 * 1.1,
            .undervoltage_threshold_kv = 230.0 * 0.9,
        };

        log.info("Transmission line initialized successfully", .{});
        return self;
    }

    pub fn deinit(self: *TransmissionLine) void {
        log.info("Deinitializing transmission line: {}", .{self.config.id});
    }

    pub fn update(self: *TransmissionLine, delta_time_seconds: f64) !void {
        if (!self.is_operational) return;

        // Update operational hours
        self.operational_hours += @intFromFloat(delta_time_seconds / 3600.0);

        // Calculate power losses
        self.power_loss_mw = self.calculatePowerLoss();

        // Check for protection triggers
        try self.checkProtectionSystems();

        // Check for random failures
        try self.checkForFailures();

        // Update thermal effects
        try self.updateThermalEffects();
    }

    pub fn calculateFlow(self: *TransmissionLine, _: anytype) f64 {
        if (!self.is_operational) return 0.0;

        // Simplified power flow calculation
        // In reality, this would solve complex power flow equations

        const voltage_diff = self.voltage_from - self.voltage_to;
        const impedance = @sqrt(self.total_resistance * self.total_resistance + self.total_reactance * self.total_reactance);

        // Calculate current flow (simplified)
        const current_amps = voltage_diff / impedance;

        // Convert to MW
        const power_flow_mw = current_amps * self.voltage_from / 1000.0;

        // Apply thermal and capacity limits
        const limited_flow = @min(power_flow_mw, self.thermal_rating_mw);

        return limited_flow;
    }

    pub fn setFlow(self: *TransmissionLine, flow_mw: f64) !void {
        if (!self.is_operational) {
            self.current_flow_mw = 0.0;
            return;
        }

        // Check thermal limits
        if (flow_mw > self.thermal_rating_mw) {
            log.warn("Transmission line {} flow exceeds thermal rating: {} > {} MW", .{ self.config.id, flow_mw, self.thermal_rating_mw });

            // Trigger thermal protection
            try self.triggerThermalProtection();
            return;
        }

        self.current_flow_mw = flow_mw;

        // Update voltages based on flow
        try self.updateVoltages();
    }

    fn updateVoltages(self: *TransmissionLine) !void {
        // Simplified voltage drop calculation
        const voltage_drop = self.current_flow_mw * self.total_resistance / 1000.0; // kV
        self.voltage_to = self.voltage_from - voltage_drop;

        // Ensure voltages stay within reasonable bounds
        self.voltage_to = @max(200.0, @min(250.0, self.voltage_to));
    }

    fn calculatePowerLoss(self: *TransmissionLine) f64 {
        // Calculate I²R losses
        const current_amps = self.current_flow_mw * 1000.0 / (self.voltage_from * @sqrt(3.0));
        const power_loss_watts = current_amps * current_amps * self.total_resistance;

        return power_loss_watts / 1000000.0; // Convert to MW
    }

    fn checkProtectionSystems(self: *TransmissionLine) !void {
        // Check overcurrent protection
        const current_amps = self.current_flow_mw * 1000.0 / (self.voltage_from * @sqrt(3.0));
        if (current_amps > self.overcurrent_threshold_amps) {
            log.warn("Overcurrent detected on line {}: {} A", .{ self.config.id, current_amps });
            try self.triggerOvercurrentProtection();
        }

        // Check overvoltage protection
        if (self.voltage_from > self.overvoltage_threshold_kv) {
            log.warn("Overvoltage detected on line {}: {} kV", .{ self.config.id, self.voltage_from });
            try self.triggerOvervoltageProtection();
        }

        // Check undervoltage protection
        if (self.voltage_to < self.undervoltage_threshold_kv) {
            log.warn("Undervoltage detected on line {}: {} kV", .{ self.config.id, self.voltage_to });
            try self.triggerUndervoltageProtection();
        }
    }

    fn checkForFailures(self: *TransmissionLine) !void {
        if (!self.is_operational) return;

        // Calculate failure probability based on age and weather
        const age_factor = 1.0 + (@as(f64, @floatFromInt(self.operational_hours)) / 87600.0); // 10 years
        const failure_prob = self.failure_probability * age_factor;

        // Simple random failure check
        const random_value = @as(f64, @floatFromInt(std.hash_map.getAutoHashFn(u64, std.HashMap(u32, PowerPlant, std.HashMap(u32, PowerPlant).Context, std.hash_map.default_max_load_percentage).Context).hash(@intCast(std.time.timestamp() + self.config.id)))) / @as(f64, @floatFromInt(std.math.maxInt(u64)));

        if (random_value < failure_prob) {
            try self.triggerFailure();
        }
    }

    fn updateThermalEffects(self: *TransmissionLine) !void {
        // Calculate conductor temperature based on current flow
        const current_amps = self.current_flow_mw * 1000.0 / (self.voltage_from * @sqrt(3.0));
        const heating_factor = (current_amps / self.current_rating_amps) * (current_amps / self.current_rating_amps);

        // Simplified thermal model
        const conductor_temp = 25.0 + (heating_factor * 50.0); // 25°C ambient + heating

        // Reduce capacity if temperature is too high
        if (conductor_temp > 75.0) {
            const derating_factor = (100.0 - conductor_temp) / 75.0;
            self.thermal_rating_mw = self.config.capacity_mw * @max(0.5, derating_factor);
        } else {
            self.thermal_rating_mw = self.config.capacity_mw * 1.1;
        }
    }

    fn triggerThermalProtection(self: *TransmissionLine) !void {
        log.err("Thermal protection triggered on line {}", .{self.config.id});
        try self.triggerFailure();
    }

    fn triggerOvercurrentProtection(self: *TransmissionLine) !void {
        log.err("Overcurrent protection triggered on line {}", .{self.config.id});
        try self.triggerFailure();
    }

    fn triggerOvervoltageProtection(self: *TransmissionLine) !void {
        log.err("Overvoltage protection triggered on line {}", .{self.config.id});
        try self.triggerFailure();
    }

    fn triggerUndervoltageProtection(self: *TransmissionLine) !void {
        log.err("Undervoltage protection triggered on line {}", .{self.config.id});
        try self.triggerFailure();
    }

    fn triggerFailure(self: *TransmissionLine) !void {
        log.warn("Transmission line {} experienced a failure", .{self.config.id});
        self.is_operational = false;
        self.current_flow_mw = 0.0;
    }

    pub fn injectFailure(self: *TransmissionLine, failure_type: @import("simulator.zig").FailureType) !void {
        log.info("Injecting {} failure into transmission line: {}", .{ @tagName(failure_type), self.config.id });

        switch (failure_type) {
            .transmission_line_fault => {
                try self.triggerFailure();
            },
            .cyber_attack => {
                // Simulate cyber attack - incorrect flow readings
                self.current_flow_mw *= 1.5; // Artificially high reading
            },
            .natural_disaster => {
                // Natural disaster - complete failure
                try self.triggerFailure();
            },
            .cascading_failure => {
                // Cascading failure - gradual degradation
                self.thermal_rating_mw *= 0.5;
                if (self.current_flow_mw > self.thermal_rating_mw) {
                    try self.triggerFailure();
                }
            },
            else => {
                log.warn("Unsupported failure type for transmission line: {}", .{@tagName(failure_type)});
            },
        }
    }

    pub fn repair(self: *TransmissionLine) !void {
        log.info("Repairing transmission line: {}", .{self.config.id});
        self.is_operational = true;
        self.current_flow_mw = 0.0;
        self.thermal_rating_mw = self.config.capacity_mw * 1.1;
        self.operational_hours = 0; // Reset operational hours after repair
    }

    pub fn isOperational(self: TransmissionLine) bool {
        return self.is_operational;
    }

    pub fn getCurrentFlow(self: TransmissionLine) f64 {
        return self.current_flow_mw;
    }

    pub fn getCapacity(self: TransmissionLine) f64 {
        return self.config.capacity_mw;
    }

    pub fn getPowerLoss(self: TransmissionLine) f64 {
        return self.power_loss_mw;
    }

    pub fn getUtilization(self: TransmissionLine) f64 {
        if (self.config.capacity_mw == 0) return 0.0;
        return self.current_flow_mw / self.config.capacity_mw;
    }

    pub fn getVoltageFrom(self: TransmissionLine) f64 {
        return self.voltage_from;
    }

    pub fn getVoltageTo(self: TransmissionLine) f64 {
        return self.voltage_to;
    }

    // Static helper functions
    fn calculateFailureProbability(length_km: f64) f64 {
        // Base failure probability increases with line length
        const base_probability = 0.02; // 2% per year
        const length_factor = 1.0 + (length_km / 100.0); // Increase with length
        return base_probability * length_factor;
    }
};
