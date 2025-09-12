package database

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User represents a system user
type User struct {
	ID           uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Email        string         `gorm:"uniqueIndex;not null" json:"email"`
	Username     string         `gorm:"uniqueIndex;not null" json:"username"`
	PasswordHash string         `gorm:"not null" json:"-"`
	Role         string         `gorm:"default:user" json:"role"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	IsActive     bool           `gorm:"default:true" json:"is_active"`
	Metadata     map[string]any `gorm:"type:jsonb" json:"metadata"`
}

// Organization represents an organization/tenant
type Organization struct {
	ID          uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name        string         `gorm:"not null" json:"name"`
	Description string         `json:"description"`
	OwnerID     uuid.UUID      `gorm:"type:uuid;not null" json:"owner_id"`
	Owner       User           `gorm:"foreignKey:OwnerID" json:"owner"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	Settings    map[string]any `gorm:"type:jsonb" json:"settings"`
}

// Simulation represents a grid simulation
type Simulation struct {
	ID             uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name           string         `gorm:"not null" json:"name"`
	Description    string         `json:"description"`
	UserID         uuid.UUID      `gorm:"type:uuid;not null" json:"user_id"`
	User           User           `gorm:"foreignKey:UserID" json:"user"`
	OrganizationID uuid.UUID      `gorm:"type:uuid" json:"organization_id"`
	Organization   Organization   `gorm:"foreignKey:OrganizationID" json:"organization"`
	Config         map[string]any `gorm:"type:jsonb;not null" json:"config"`
	Status         string         `gorm:"default:created" json:"status"`
	CreatedAt      time.Time      `json:"created_at"`
	StartedAt      *time.Time     `json:"started_at"`
	CompletedAt    *time.Time     `json:"completed_at"`
	ErrorMessage   string         `json:"error_message"`
	Metadata       map[string]any `gorm:"type:jsonb" json:"metadata"`

	// Relationships
	PowerPlants       []PowerPlant       `gorm:"foreignKey:SimulationID" json:"power_plants"`
	TransmissionLines []TransmissionLine `gorm:"foreignKey:SimulationID" json:"transmission_lines"`
	Results           []SimulationResult `gorm:"foreignKey:SimulationID" json:"results"`
	ComponentMetrics  []ComponentMetric  `gorm:"foreignKey:SimulationID" json:"component_metrics"`
	FaultEvents       []FaultEvent       `gorm:"foreignKey:SimulationID" json:"fault_events"`
	Alerts            []Alert            `gorm:"foreignKey:SimulationID" json:"alerts"`
}

// PowerPlant represents a power generation unit
type PowerPlant struct {
	ID              uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	SimulationID    uuid.UUID      `gorm:"type:uuid;not null" json:"simulation_id"`
	Simulation      Simulation     `gorm:"foreignKey:SimulationID" json:"simulation"`
	PlantID         int            `gorm:"not null" json:"plant_id"`
	Name            string         `gorm:"not null" json:"name"`
	PlantType       string         `gorm:"not null" json:"plant_type"`
	MaxCapacityMW   float64        `gorm:"not null" json:"max_capacity_mw"`
	CurrentOutputMW float64        `gorm:"not null" json:"current_output_mw"`
	Efficiency      float64        `gorm:"not null" json:"efficiency"`
	Location        map[string]any `gorm:"type:jsonb;not null" json:"location"`
	IsOperational   bool           `gorm:"default:true" json:"is_operational"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
}

// TransmissionLine represents a power transmission line
type TransmissionLine struct {
	ID              uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	SimulationID    uuid.UUID  `gorm:"type:uuid;not null" json:"simulation_id"`
	Simulation      Simulation `gorm:"foreignKey:SimulationID" json:"simulation"`
	LineID          int        `gorm:"not null" json:"line_id"`
	FromNode        int        `gorm:"not null" json:"from_node"`
	ToNode          int        `gorm:"not null" json:"to_node"`
	CapacityMW      float64    `gorm:"not null" json:"capacity_mw"`
	LengthKM        float64    `gorm:"not null" json:"length_km"`
	ResistancePerKM float64    `gorm:"not null" json:"resistance_per_km"`
	ReactancePerKM  float64    `gorm:"not null" json:"reactance_per_km"`
	IsOperational   bool       `gorm:"default:true" json:"is_operational"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

// SimulationResult represents time-series simulation data
type SimulationResult struct {
	ID                   uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	SimulationID         uuid.UUID      `gorm:"type:uuid;not null" json:"simulation_id"`
	Simulation           Simulation     `gorm:"foreignKey:SimulationID" json:"simulation"`
	Timestamp            time.Time      `gorm:"not null;index:idx_simulation_timestamp,priority:1" json:"timestamp"`
	TickNumber           int            `gorm:"not null" json:"tick_number"`
	TotalGenerationMW    float64        `gorm:"not null" json:"total_generation_mw"`
	TotalConsumptionMW   float64        `gorm:"not null" json:"total_consumption_mw"`
	GridFrequencyHz      float64        `gorm:"not null" json:"grid_frequency_hz"`
	GridVoltageKV        float64        `gorm:"not null" json:"grid_voltage_kv"`
	EfficiencyPercentage float64        `gorm:"not null" json:"efficiency_percentage"`
	FaultCount           int            `gorm:"default:0" json:"fault_count"`
	Metadata             map[string]any `gorm:"type:jsonb" json:"metadata"`
}

// ComponentMetric represents detailed metrics for individual components
type ComponentMetric struct {
	ID            uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	SimulationID  uuid.UUID      `gorm:"type:uuid;not null" json:"simulation_id"`
	Simulation    Simulation     `gorm:"foreignKey:SimulationID" json:"simulation"`
	ComponentType string         `gorm:"not null;index:idx_component_timestamp,priority:1" json:"component_type"`
	ComponentID   int            `gorm:"not null;index:idx_component_timestamp,priority:2" json:"component_id"`
	Timestamp     time.Time      `gorm:"not null;index:idx_component_timestamp,priority:3" json:"timestamp"`
	MetricName    string         `gorm:"not null" json:"metric_name"`
	MetricValue   float64        `gorm:"not null" json:"metric_value"`
	Unit          string         `gorm:"not null" json:"unit"`
	Metadata      map[string]any `gorm:"type:jsonb" json:"metadata"`
}

// FaultEvent represents a fault event in the grid
type FaultEvent struct {
	ID               uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	SimulationID     uuid.UUID      `gorm:"type:uuid;not null" json:"simulation_id"`
	Simulation       Simulation     `gorm:"foreignKey:SimulationID" json:"simulation"`
	Timestamp        time.Time      `gorm:"not null;index:idx_simulation_faults,priority:2" json:"timestamp"`
	FaultType        string         `gorm:"not null;index:idx_fault_type" json:"fault_type"`
	ComponentID      int            `gorm:"not null" json:"component_id"`
	ComponentType    string         `gorm:"not null" json:"component_type"`
	Severity         string         `gorm:"not null" json:"severity"`
	Description      string         `json:"description"`
	ResolvedAt       *time.Time     `json:"resolved_at"`
	ImpactAssessment map[string]any `gorm:"type:jsonb" json:"impact_assessment"`
}

// Alert represents a system alert
type Alert struct {
	ID             uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	SimulationID   uuid.UUID      `gorm:"type:uuid" json:"simulation_id"`
	Simulation     Simulation     `gorm:"foreignKey:SimulationID" json:"simulation"`
	AlertType      string         `gorm:"not null;index:idx_alert_type" json:"alert_type"`
	Severity       string         `gorm:"not null" json:"severity"`
	Message        string         `gorm:"not null" json:"message"`
	TriggeredAt    time.Time      `gorm:"default:now();index:idx_simulation_alerts,priority:2" json:"triggered_at"`
	AcknowledgedAt *time.Time     `json:"acknowledged_at"`
	ResolvedAt     *time.Time     `json:"resolved_at"`
	Metadata       map[string]any `gorm:"type:jsonb" json:"metadata"`
}

// TableName returns the table name for GORM
func (User) TableName() string {
	return "users"
}

func (Organization) TableName() string {
	return "organizations"
}

func (Simulation) TableName() string {
	return "simulations"
}

func (PowerPlant) TableName() string {
	return "power_plants"
}

func (TransmissionLine) TableName() string {
	return "transmission_lines"
}

func (SimulationResult) TableName() string {
	return "simulation_results"
}

func (ComponentMetric) TableName() string {
	return "component_metrics"
}

func (FaultEvent) TableName() string {
	return "fault_events"
}

func (Alert) TableName() string {
	return "alerts"
}

// BeforeCreate hook for UUID generation
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}

func (o *Organization) BeforeCreate(tx *gorm.DB) error {
	if o.ID == uuid.Nil {
		o.ID = uuid.New()
	}
	return nil
}

func (s *Simulation) BeforeCreate(tx *gorm.DB) error {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return nil
}

func (pp *PowerPlant) BeforeCreate(tx *gorm.DB) error {
	if pp.ID == uuid.Nil {
		pp.ID = uuid.New()
	}
	return nil
}

func (tl *TransmissionLine) BeforeCreate(tx *gorm.DB) error {
	if tl.ID == uuid.Nil {
		tl.ID = uuid.New()
	}
	return nil
}

func (sr *SimulationResult) BeforeCreate(tx *gorm.DB) error {
	if sr.ID == uuid.Nil {
		sr.ID = uuid.New()
	}
	return nil
}

func (cm *ComponentMetric) BeforeCreate(tx *gorm.DB) error {
	if cm.ID == uuid.Nil {
		cm.ID = uuid.New()
	}
	return nil
}

func (fe *FaultEvent) BeforeCreate(tx *gorm.DB) error {
	if fe.ID == uuid.Nil {
		fe.ID = uuid.New()
	}
	return nil
}

func (a *Alert) BeforeCreate(tx *gorm.DB) error {
	if a.ID == uuid.Nil {
		a.ID = uuid.New()
	}
	return nil
}

