-- VoltEdge Energy Grid Database Schema
-- CockroachDB initialization script

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS voltedge;

-- Use the voltedge database
USE voltedge;

-- Create users table for multi-tenant support
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email STRING UNIQUE NOT NULL,
    username STRING UNIQUE NOT NULL,
    password_hash STRING NOT NULL,
    role STRING NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    is_active BOOLEAN DEFAULT true,
    metadata JSONB
);

-- Create organizations table for enterprise features
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name STRING NOT NULL,
    description STRING,
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    settings JSONB
);

-- Create simulations table
CREATE TABLE IF NOT EXISTS simulations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name STRING NOT NULL,
    description STRING,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    config JSONB NOT NULL,
    status STRING NOT NULL DEFAULT 'created',
    created_at TIMESTAMPTZ DEFAULT now(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_message STRING,
    metadata JSONB
);

-- Create power plants table
CREATE TABLE IF NOT EXISTS power_plants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
    plant_id INT NOT NULL,
    name STRING NOT NULL,
    plant_type STRING NOT NULL,
    max_capacity_mw FLOAT NOT NULL,
    current_output_mw FLOAT NOT NULL,
    efficiency FLOAT NOT NULL,
    location JSONB NOT NULL,
    is_operational BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create transmission lines table
CREATE TABLE IF NOT EXISTS transmission_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
    line_id INT NOT NULL,
    from_node INT NOT NULL,
    to_node INT NOT NULL,
    capacity_mw FLOAT NOT NULL,
    length_km FLOAT NOT NULL,
    resistance_per_km FLOAT NOT NULL,
    reactance_per_km FLOAT NOT NULL,
    is_operational BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create simulation results table for time-series data
CREATE TABLE IF NOT EXISTS simulation_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ NOT NULL,
    tick_number INT NOT NULL,
    total_generation_mw FLOAT NOT NULL,
    total_consumption_mw FLOAT NOT NULL,
    grid_frequency_hz FLOAT NOT NULL,
    grid_voltage_kv FLOAT NOT NULL,
    efficiency_percentage FLOAT NOT NULL,
    fault_count INT NOT NULL DEFAULT 0,
    metadata JSONB,
    INDEX idx_simulation_timestamp (simulation_id, timestamp),
    INDEX idx_timestamp (timestamp)
);

-- Create detailed metrics table for individual components
CREATE TABLE IF NOT EXISTS component_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
    component_type STRING NOT NULL,
    component_id INT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    metric_name STRING NOT NULL,
    metric_value FLOAT NOT NULL,
    unit STRING NOT NULL,
    metadata JSONB,
    INDEX idx_component_timestamp (component_type, component_id, timestamp),
    INDEX idx_simulation_component (simulation_id, component_type, component_id)
);

-- Create fault events table
CREATE TABLE IF NOT EXISTS fault_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ NOT NULL,
    fault_type STRING NOT NULL,
    component_id INT NOT NULL,
    component_type STRING NOT NULL,
    severity STRING NOT NULL,
    description STRING,
    resolved_at TIMESTAMPTZ,
    impact_assessment JSONB,
    INDEX idx_simulation_faults (simulation_id, timestamp),
    INDEX idx_fault_type (fault_type)
);

-- Create alerts table for monitoring
CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
    alert_type STRING NOT NULL,
    severity STRING NOT NULL,
    message STRING NOT NULL,
    triggered_at TIMESTAMPTZ DEFAULT now(),
    acknowledged_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    metadata JSONB,
    INDEX idx_simulation_alerts (simulation_id, triggered_at),
    INDEX idx_alert_type (alert_type)
);

-- Create indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_simulations_user ON simulations(user_id);
CREATE INDEX IF NOT EXISTS idx_simulations_org ON simulations(organization_id);
CREATE INDEX IF NOT EXISTS idx_simulations_status ON simulations(status);
CREATE INDEX IF NOT EXISTS idx_power_plants_sim ON power_plants(simulation_id);
CREATE INDEX IF NOT EXISTS idx_transmission_lines_sim ON transmission_lines(simulation_id);

-- Create views for common queries
CREATE VIEW IF NOT EXISTS simulation_summary AS
SELECT 
    s.id,
    s.name,
    s.status,
    s.created_at,
    u.username as created_by,
    o.name as organization_name,
    COUNT(DISTINCT pp.id) as power_plant_count,
    COUNT(DISTINCT tl.id) as transmission_line_count,
    COALESCE(AVG(sr.total_generation_mw), 0) as avg_generation_mw,
    COALESCE(AVG(sr.total_consumption_mw), 0) as avg_consumption_mw,
    COALESCE(AVG(sr.efficiency_percentage), 0) as avg_efficiency
FROM simulations s
LEFT JOIN users u ON s.user_id = u.id
LEFT JOIN organizations o ON s.organization_id = o.id
LEFT JOIN power_plants pp ON s.id = pp.simulation_id
LEFT JOIN transmission_lines tl ON s.id = tl.simulation_id
LEFT JOIN simulation_results sr ON s.id = sr.simulation_id
GROUP BY s.id, s.name, s.status, s.created_at, u.username, o.name;

-- Create view for real-time grid status
CREATE VIEW IF NOT EXISTS real_time_grid_status AS
SELECT 
    s.id as simulation_id,
    s.name as simulation_name,
    sr.timestamp,
    sr.tick_number,
    sr.total_generation_mw,
    sr.total_consumption_mw,
    sr.grid_frequency_hz,
    sr.grid_voltage_kv,
    sr.efficiency_percentage,
    sr.fault_count,
    CASE 
        WHEN sr.grid_frequency_hz < 49.5 OR sr.grid_frequency_hz > 50.5 THEN 'CRITICAL'
        WHEN sr.efficiency_percentage < 85 THEN 'WARNING'
        ELSE 'NORMAL'
    END as grid_status
FROM simulations s
JOIN simulation_results sr ON s.id = sr.simulation_id
WHERE s.status = 'running'
ORDER BY sr.timestamp DESC
LIMIT 1000;

-- Insert default admin user
INSERT INTO users (email, username, password_hash, role) 
VALUES (
    'admin@voltedge.com', 
    'admin', 
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: password
    'admin'
) ON CONFLICT (email) DO NOTHING;

-- Insert default organization
INSERT INTO organizations (name, description, owner_id)
SELECT 
    'VoltEdge Demo Organization',
    'Default organization for VoltEdge demonstrations',
    id
FROM users 
WHERE username = 'admin'
ON CONFLICT DO NOTHING;

-- Create functions for common operations
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at columns
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_simulations_updated_at BEFORE UPDATE ON simulations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_power_plants_updated_at BEFORE UPDATE ON power_plants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transmission_lines_updated_at BEFORE UPDATE ON transmission_lines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL ON DATABASE voltedge TO voltedge;
GRANT ALL ON ALL TABLES IN SCHEMA public TO voltedge;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO voltedge;

