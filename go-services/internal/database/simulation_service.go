package database

import (
	"time"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

// SimulationService provides simulation-specific database operations
type SimulationService struct {
	db     *gorm.DB
	logger *logrus.Logger
}

// NewSimulationService creates a new simulation service
func NewSimulationService(db *gorm.DB, logger *logrus.Logger) *SimulationService {
	return &SimulationService{
		db:     db,
		logger: logger,
	}
}

// CreateSimulation creates a new simulation
func (s *SimulationService) CreateSimulation(simulation *Simulation) error {
	if err := s.db.Create(simulation).Error; err != nil {
		s.logger.WithError(err).Error("Failed to create simulation")
		return err
	}

	s.logger.WithFields(logrus.Fields{
		"simulation_id": simulation.ID,
		"name":          simulation.Name,
		"user_id":       simulation.UserID,
	}).Info("Simulation created successfully")

	return nil
}

// GetSimulation retrieves a simulation by ID with all relationships
func (s *SimulationService) GetSimulation(id uuid.UUID) (*Simulation, error) {
	var simulation Simulation

	err := s.db.Preload("User").
		Preload("Organization").
		Preload("PowerPlants").
		Preload("TransmissionLines").
		First(&simulation, id).Error

	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		s.logger.WithError(err).Error("Failed to get simulation")
		return nil, err
	}

	return &simulation, nil
}

// GetSimulationsByUser retrieves simulations for a specific user
func (s *SimulationService) GetSimulationsByUser(userID uuid.UUID, limit, offset int) ([]Simulation, error) {
	var simulations []Simulation

	err := s.db.Where("user_id = ?", userID).
		Preload("User").
		Preload("Organization").
		Limit(limit).
		Offset(offset).
		Order("created_at DESC").
		Find(&simulations).Error

	if err != nil {
		s.logger.WithError(err).Error("Failed to get simulations by user")
		return nil, err
	}

	return simulations, nil
}

// UpdateSimulationStatus updates the status of a simulation
func (s *SimulationService) UpdateSimulationStatus(id uuid.UUID, status string) error {
	updates := map[string]interface{}{
		"status":     status,
		"updated_at": time.Now(),
	}

	if status == "running" {
		now := time.Now()
		updates["started_at"] = &now
	} else if status == "completed" || status == "failed" {
		now := time.Now()
		updates["completed_at"] = &now
	}

	err := s.db.Model(&Simulation{}).Where("id = ?", id).Updates(updates).Error
	if err != nil {
		s.logger.WithError(err).Error("Failed to update simulation status")
		return err
	}

	s.logger.WithFields(logrus.Fields{
		"simulation_id": id,
		"status":        status,
	}).Info("Simulation status updated")

	return nil
}

// AddSimulationResult adds a new simulation result
func (s *SimulationService) AddSimulationResult(result *SimulationResult) error {
	if err := s.db.Create(result).Error; err != nil {
		s.logger.WithError(err).Error("Failed to add simulation result")
		return err
	}
	return nil
}

// GetSimulationResults retrieves simulation results with pagination
func (s *SimulationService) GetSimulationResults(simulationID uuid.UUID, limit, offset int) ([]SimulationResult, error) {
	var results []SimulationResult

	err := s.db.Where("simulation_id = ?", simulationID).
		Order("timestamp DESC").
		Limit(limit).
		Offset(offset).
		Find(&results).Error

	if err != nil {
		s.logger.WithError(err).Error("Failed to get simulation results")
		return nil, err
	}

	return results, nil
}

// GetLatestSimulationResults retrieves the latest N results for a simulation
func (s *SimulationService) GetLatestSimulationResults(simulationID uuid.UUID, limit int) ([]SimulationResult, error) {
	var results []SimulationResult

	err := s.db.Where("simulation_id = ?", simulationID).
		Order("timestamp DESC").
		Limit(limit).
		Find(&results).Error

	if err != nil {
		s.logger.WithError(err).Error("Failed to get latest simulation results")
		return nil, err
	}

	return results, nil
}

// AddComponentMetric adds a component metric
func (s *SimulationService) AddComponentMetric(metric *ComponentMetric) error {
	if err := s.db.Create(metric).Error; err != nil {
		s.logger.WithError(err).Error("Failed to add component metric")
		return err
	}
	return nil
}

// GetComponentMetrics retrieves component metrics
func (s *SimulationService) GetComponentMetrics(simulationID uuid.UUID, componentType string, componentID int, limit int) ([]ComponentMetric, error) {
	var metrics []ComponentMetric

	query := s.db.Where("simulation_id = ?", simulationID)

	if componentType != "" {
		query = query.Where("component_type = ?", componentType)
	}

	if componentID >= 0 {
		query = query.Where("component_id = ?", componentID)
	}

	err := query.Order("timestamp DESC").
		Limit(limit).
		Find(&metrics).Error

	if err != nil {
		s.logger.WithError(err).Error("Failed to get component metrics")
		return nil, err
	}

	return metrics, nil
}

// AddFaultEvent adds a fault event
func (s *SimulationService) AddFaultEvent(event *FaultEvent) error {
	if err := s.db.Create(event).Error; err != nil {
		s.logger.WithError(err).Error("Failed to add fault event")
		return err
	}

	s.logger.WithFields(logrus.Fields{
		"simulation_id": event.SimulationID,
		"fault_type":    event.FaultType,
		"component_id":  event.ComponentID,
		"severity":      event.Severity,
	}).Info("Fault event added")

	return nil
}

// GetFaultEvents retrieves fault events for a simulation
func (s *SimulationService) GetFaultEvents(simulationID uuid.UUID, limit, offset int) ([]FaultEvent, error) {
	var events []FaultEvent

	err := s.db.Where("simulation_id = ?", simulationID).
		Order("timestamp DESC").
		Limit(limit).
		Offset(offset).
		Find(&events).Error

	if err != nil {
		s.logger.WithError(err).Error("Failed to get fault events")
		return nil, err
	}

	return events, nil
}

// AddAlert adds an alert
func (s *SimulationService) AddAlert(alert *Alert) error {
	if err := s.db.Create(alert).Error; err != nil {
		s.logger.WithError(err).Error("Failed to add alert")
		return err
	}

	s.logger.WithFields(logrus.Fields{
		"simulation_id": alert.SimulationID,
		"alert_type":    alert.AlertType,
		"severity":      alert.Severity,
		"message":       alert.Message,
	}).Info("Alert added")

	return nil
}

// GetActiveAlerts retrieves active alerts for a simulation
func (s *SimulationService) GetActiveAlerts(simulationID uuid.UUID) ([]Alert, error) {
	var alerts []Alert

	err := s.db.Where("simulation_id = ? AND resolved_at IS NULL", simulationID).
		Order("triggered_at DESC").
		Find(&alerts).Error

	if err != nil {
		s.logger.WithError(err).Error("Failed to get active alerts")
		return nil, err
	}

	return alerts, nil
}

// GetSimulationStatistics retrieves statistics for a simulation
func (s *SimulationService) GetSimulationStatistics(simulationID uuid.UUID) (map[string]interface{}, error) {
	var stats map[string]interface{} = make(map[string]interface{})

	// Get total results count
	var totalResults int64
	if err := s.db.Model(&SimulationResult{}).Where("simulation_id = ?", simulationID).Count(&totalResults).Error; err != nil {
		s.logger.WithError(err).Error("Failed to count simulation results")
		return nil, err
	}
	stats["total_results"] = totalResults

	// Get latest result
	var latestResult SimulationResult
	err := s.db.Where("simulation_id = ?", simulationID).
		Order("timestamp DESC").
		First(&latestResult).Error
	if err == nil {
		stats["latest_result"] = latestResult
	}

	// Get fault count
	var faultCount int64
	if err := s.db.Model(&FaultEvent{}).Where("simulation_id = ?", simulationID).Count(&faultCount).Error; err != nil {
		s.logger.WithError(err).Error("Failed to count fault events")
		return nil, err
	}
	stats["fault_count"] = faultCount

	// Get active alerts count
	var activeAlertsCount int64
	if err := s.db.Model(&Alert{}).Where("simulation_id = ? AND resolved_at IS NULL", simulationID).Count(&activeAlertsCount).Error; err != nil {
		s.logger.WithError(err).Error("Failed to count active alerts")
		return nil, err
	}
	stats["active_alerts"] = activeAlertsCount

	// Get average metrics
	var avgMetrics struct {
		AvgGenerationMW    float64 `json:"avg_generation_mw"`
		AvgConsumptionMW   float64 `json:"avg_consumption_mw"`
		AvgEfficiency      float64 `json:"avg_efficiency"`
		AvgGridFrequencyHz float64 `json:"avg_grid_frequency_hz"`
	}

	err = s.db.Model(&SimulationResult{}).
		Where("simulation_id = ?", simulationID).
		Select("AVG(total_generation_mw) as avg_generation_mw, AVG(total_consumption_mw) as avg_consumption_mw, AVG(efficiency_percentage) as avg_efficiency, AVG(grid_frequency_hz) as avg_grid_frequency_hz").
		Scan(&avgMetrics).Error

	if err != nil {
		s.logger.WithError(err).Error("Failed to calculate average metrics")
	} else {
		stats["average_metrics"] = avgMetrics
	}

	return stats, nil
}

// DeleteSimulation deletes a simulation and all related data
func (s *SimulationService) DeleteSimulation(id uuid.UUID) error {
	// Use transaction to ensure data consistency
	return s.db.Transaction(func(tx *gorm.DB) error {
		// Delete in reverse order of dependencies
		if err := tx.Where("simulation_id = ?", id).Delete(&Alert{}).Error; err != nil {
			return err
		}

		if err := tx.Where("simulation_id = ?", id).Delete(&FaultEvent{}).Error; err != nil {
			return err
		}

		if err := tx.Where("simulation_id = ?", id).Delete(&ComponentMetric{}).Error; err != nil {
			return err
		}

		if err := tx.Where("simulation_id = ?", id).Delete(&SimulationResult{}).Error; err != nil {
			return err
		}

		if err := tx.Where("simulation_id = ?", id).Delete(&TransmissionLine{}).Error; err != nil {
			return err
		}

		if err := tx.Where("simulation_id = ?", id).Delete(&PowerPlant{}).Error; err != nil {
			return err
		}

		if err := tx.Delete(&Simulation{}, id).Error; err != nil {
			return err
		}

		s.logger.WithField("simulation_id", id).Info("Simulation and all related data deleted")
		return nil
	})
}

