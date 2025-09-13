package orchestration

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/sirupsen/logrus"

	"voltedge/go-services/internal/config"
)

// SimulationStatus represents the status of a simulation
type SimulationStatus int

const (
	StatusIdle SimulationStatus = iota
	StatusRunning
	StatusPaused
	StatusError
	StatusCompleted
)

func (s SimulationStatus) String() string {
	switch s {
	case StatusIdle:
		return "idle"
	case StatusRunning:
		return "running"
	case StatusPaused:
		return "paused"
	case StatusError:
		return "error"
	case StatusCompleted:
		return "completed"
	default:
		return "unknown"
	}
}

// Simulation represents a simulation instance
type Simulation struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Description string                 `json:"description"`
	Status      SimulationStatus       `json:"status"`
	Config      SimulationConfig       `json:"config"`
	Tags        []string               `json:"tags"`
	Metadata    map[string]interface{} `json:"metadata"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`

	// Runtime information
	StartTime *time.Time    `json:"start_time,omitempty"`
	EndTime   *time.Time    `json:"end_time,omitempty"`
	Duration  time.Duration `json:"duration,omitempty"`
	Error     error         `json:"error,omitempty"`

	// Performance metrics
	EventsProcessed int64   `json:"events_processed"`
	AvgTickTime     float64 `json:"avg_tick_time_ms"`
	MemoryUsage     int64   `json:"memory_usage_mb"`
}

// SimulationConfig represents the configuration for a simulation
type SimulationConfig struct {
	PowerPlants       []PowerPlantConfig       `json:"power_plants"`
	TransmissionLines []TransmissionLineConfig `json:"transmission_lines"`
	BaseFrequency     float64                  `json:"base_frequency"`
	BaseVoltage       float64                  `json:"base_voltage"`
	LoadProfile       LoadProfile              `json:"load_profile"`
}

// PowerPlantConfig represents a power plant configuration
type PowerPlantConfig struct {
	ID              string   `json:"id"`
	Name            string   `json:"name"`
	Type            string   `json:"type"`
	MaxCapacityMW   float64  `json:"max_capacity_mw"`
	CurrentOutputMW float64  `json:"current_output_mw"`
	Efficiency      float64  `json:"efficiency"`
	Location        Location `json:"location"`
	IsOperational   bool     `json:"is_operational"`
}

// TransmissionLineConfig represents a transmission line configuration
type TransmissionLineConfig struct {
	ID              string  `json:"id"`
	FromNode        string  `json:"from_node"`
	ToNode          string  `json:"to_node"`
	CapacityMW      float64 `json:"capacity_mw"`
	LengthKM        float64 `json:"length_km"`
	ResistancePerKM float64 `json:"resistance_per_km"`
	ReactancePerKM  float64 `json:"reactance_per_km"`
	IsOperational   bool    `json:"is_operational"`
}

// LoadProfile represents the load profile configuration
type LoadProfile struct {
	BaseLoadMW      float64 `json:"base_load_mw"`
	PeakMultiplier  float64 `json:"peak_multiplier"`
	DailyVariation  float64 `json:"daily_variation"`
	RandomVariation float64 `json:"random_variation"`
}

// Location represents a geographical location
type Location struct {
	X    float64 `json:"x"`
	Y    float64 `json:"y"`
	Name string  `json:"name"`
}

// HealthStatus represents the health status of a service
type HealthStatus struct {
	IsHealthy bool      `json:"is_healthy"`
	Message   string    `json:"message"`
	Timestamp time.Time `json:"timestamp"`
}

// Orchestrator manages simulation orchestration
type Orchestrator struct {
	config        *config.OrchestrationConfig
	simulations   map[string]*Simulation
	mu            sync.RWMutex
	ctx           context.Context
	cancel        context.CancelFunc
	workerPool    *WorkerPool
	cleanupTicker *time.Ticker
}

// NewOrchestrator creates a new orchestrator instance
func NewOrchestrator(cfg *config.OrchestrationConfig) *Orchestrator {
	ctx, cancel := context.WithCancel(context.Background())

	return &Orchestrator{
		config:      cfg,
		simulations: make(map[string]*Simulation),
		ctx:         ctx,
		cancel:      cancel,
		workerPool:  NewWorkerPool(cfg.WorkerPoolSize),
	}
}

// Start starts the orchestrator
func (o *Orchestrator) Start(ctx context.Context) error {
	logrus.Info("Starting simulation orchestrator")

	// Start worker pool
	if err := o.workerPool.Start(ctx); err != nil {
		return fmt.Errorf("failed to start worker pool: %w", err)
	}

	// Start cleanup ticker
	o.cleanupTicker = time.NewTicker(o.config.CleanupInterval)
	go o.cleanupLoop()

	logrus.Info("Simulation orchestrator started successfully")
	return nil
}

// Stop stops the orchestrator
func (o *Orchestrator) Stop() {
	logrus.Info("Stopping simulation orchestrator")

	o.cancel()

	if o.cleanupTicker != nil {
		o.cleanupTicker.Stop()
	}

	o.workerPool.Stop()

	logrus.Info("Simulation orchestrator stopped")
}

// CreateSimulation creates a new simulation
func (o *Orchestrator) CreateSimulation(name, description string, config SimulationConfig, tags []string, metadata map[string]interface{}) (*Simulation, error) {
	o.mu.Lock()
	defer o.mu.Unlock()

	// Check if we've reached the maximum number of simulations
	if len(o.simulations) >= o.config.MaxConcurrentSimulations {
		return nil, fmt.Errorf("maximum concurrent simulations reached: %d", o.config.MaxConcurrentSimulations)
	}

	// Generate unique ID
	id := generateSimulationID()

	simulation := &Simulation{
		ID:          id,
		Name:        name,
		Description: description,
		Status:      StatusIdle,
		Config:      config,
		Tags:        tags,
		Metadata:    metadata,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	o.simulations[id] = simulation

	logrus.WithFields(logrus.Fields{
		"simulation_id": id,
		"name":          name,
		"plants":        len(config.PowerPlants),
		"lines":         len(config.TransmissionLines),
	}).Info("Simulation created")

	return simulation, nil
}

// GetSimulation retrieves a simulation by ID
func (o *Orchestrator) GetSimulation(id string) (*Simulation, error) {
	o.mu.RLock()
	defer o.mu.RUnlock()

	simulation, exists := o.simulations[id]
	if !exists {
		return nil, ErrSimulationNotFound
	}

	return simulation, nil
}

// ListSimulations lists simulations with pagination and filtering
func (o *Orchestrator) ListSimulations(page, limit int, status string, tags []string) ([]*Simulation, int, error) {
	o.mu.RLock()
	defer o.mu.RUnlock()

	var filtered []*Simulation

	for _, sim := range o.simulations {
		// Filter by status
		if status != "" && sim.Status.String() != status {
			continue
		}

		// Filter by tags
		if len(tags) > 0 && !hasAnyTag(sim.Tags, tags) {
			continue
		}

		filtered = append(filtered, sim)
	}

	// Apply pagination
	total := len(filtered)
	start := (page - 1) * limit
	end := start + limit

	if start >= total {
		return []*Simulation{}, total, nil
	}

	if end > total {
		end = total
	}

	return filtered[start:end], total, nil
}

// DeleteSimulation deletes a simulation
func (o *Orchestrator) DeleteSimulation(id string) error {
	o.mu.Lock()
	defer o.mu.Unlock()

	simulation, exists := o.simulations[id]
	if !exists {
		return ErrSimulationNotFound
	}

	// Stop simulation if it's running
	if simulation.Status == StatusRunning {
		if err := o.stopSimulationInternal(id); err != nil {
			logrus.WithError(err).WithField("simulation_id", id).Error("Failed to stop simulation before deletion")
		}
	}

	delete(o.simulations, id)

	logrus.WithField("simulation_id", id).Info("Simulation deleted")
	return nil
}

// StartSimulation starts a simulation
func (o *Orchestrator) StartSimulation(id string) error {
	o.mu.Lock()
	defer o.mu.Unlock()

	return o.startSimulationInternal(id)
}

// StopSimulation stops a simulation
func (o *Orchestrator) StopSimulation(id string) error {
	o.mu.Lock()
	defer o.mu.Unlock()

	return o.stopSimulationInternal(id)
}

// PauseSimulation pauses a simulation
func (o *Orchestrator) PauseSimulation(id string) error {
	o.mu.Lock()
	defer o.mu.Unlock()

	simulation, exists := o.simulations[id]
	if !exists {
		return ErrSimulationNotFound
	}

	if simulation.Status != StatusRunning {
		return fmt.Errorf("simulation is not running, current status: %s", simulation.Status.String())
	}

	simulation.Status = StatusPaused
	simulation.UpdatedAt = time.Now()

	logrus.WithField("simulation_id", id).Info("Simulation paused")
	return nil
}

// startSimulationInternal starts a simulation (must be called with lock held)
func (o *Orchestrator) startSimulationInternal(id string) error {
	simulation, exists := o.simulations[id]
	if !exists {
		return ErrSimulationNotFound
	}

	if simulation.Status == StatusRunning {
		return fmt.Errorf("simulation is already running")
	}

	// Create a job for the worker pool
	job := &SimulationJob{
		SimulationID: id,
		Config:       simulation.Config,
		Status:       &simulation.Status,
		StartTime:    &simulation.StartTime,
		EndTime:      &simulation.EndTime,
		Error:        &simulation.Error,
		Metrics:      &simulation.EventsProcessed,
	}

	// Submit job to worker pool
	if err := o.workerPool.SubmitJob(job); err != nil {
		return fmt.Errorf("failed to submit simulation job: %w", err)
	}

	simulation.Status = StatusRunning
	now := time.Now()
	simulation.StartTime = &now
	simulation.UpdatedAt = now

	logrus.WithField("simulation_id", id).Info("Simulation started")
	return nil
}

// stopSimulationInternal stops a simulation (must be called with lock held)
func (o *Orchestrator) stopSimulationInternal(id string) error {
	simulation, exists := o.simulations[id]
	if !exists {
		return ErrSimulationNotFound
	}

	if simulation.Status != StatusRunning {
		return fmt.Errorf("simulation is not running, current status: %s", simulation.Status.String())
	}

	// Cancel the job in the worker pool
	o.workerPool.CancelJob(id)

	simulation.Status = StatusCompleted
	now := time.Now()
	simulation.EndTime = &now
	simulation.Duration = now.Sub(*simulation.StartTime)
	simulation.UpdatedAt = now

	logrus.WithField("simulation_id", id).Info("Simulation stopped")
	return nil
}

// Health returns the health status of the orchestrator
func (o *Orchestrator) Health() HealthStatus {
	o.mu.RLock()
	defer o.mu.RUnlock()

	status := HealthStatus{
		IsHealthy: true,
		Message:   "Orchestrator is healthy",
		Timestamp: time.Now(),
	}

	// Check if we're at capacity
	if len(o.simulations) >= o.config.MaxConcurrentSimulations {
		status.IsHealthy = false
		status.Message = "At maximum simulation capacity"
	}

	// Check worker pool health
	workerHealth := o.workerPool.Health()
	if !workerHealth.IsHealthy {
		status.IsHealthy = false
		status.Message = "Worker pool is unhealthy: " + workerHealth.Message
	}

	return status
}

// cleanupLoop runs the cleanup process
func (o *Orchestrator) cleanupLoop() {
	for {
		select {
		case <-o.ctx.Done():
			return
		case <-o.cleanupTicker.C:
			o.cleanup()
		}
	}
}

// cleanup removes old completed simulations
func (o *Orchestrator) cleanup() {
	o.mu.Lock()
	defer o.mu.Unlock()

	cutoff := time.Now().Add(-24 * time.Hour) // Keep completed simulations for 24 hours
	var toDelete []string

	for id, sim := range o.simulations {
		if sim.Status == StatusCompleted && sim.EndTime != nil && sim.EndTime.Before(cutoff) {
			toDelete = append(toDelete, id)
		}
	}

	for _, id := range toDelete {
		delete(o.simulations, id)
		logrus.WithField("simulation_id", id).Info("Cleaned up old simulation")
	}

	if len(toDelete) > 0 {
		logrus.WithField("count", len(toDelete)).Info("Cleaned up old simulations")
	}
}

// Helper functions

func generateSimulationID() string {
	return fmt.Sprintf("sim_%d", time.Now().UnixNano())
}

func hasAnyTag(simulationTags, filterTags []string) bool {
	for _, filterTag := range filterTags {
		for _, simTag := range simulationTags {
			if simTag == filterTag {
				return true
			}
		}
	}
	return false
}

// Errors
var (
	ErrSimulationNotFound = fmt.Errorf("simulation not found")
)


