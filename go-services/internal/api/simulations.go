package api

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"

	"voltedge/go-services/internal/orchestration"
)

// CreateSimulationRequest represents a request to create a new simulation
type CreateSimulationRequest struct {
	Name        string                 `json:"name" binding:"required"`
	Description string                 `json:"description"`
	Config      SimulationConfig       `json:"config" binding:"required"`
	Tags        []string               `json:"tags"`
	Metadata    map[string]interface{} `json:"metadata"`
}

// SimulationConfig represents the configuration for a simulation
type SimulationConfig struct {
	PowerPlants       []PowerPlantConfig       `json:"power_plants" binding:"required"`
	TransmissionLines []TransmissionLineConfig `json:"transmission_lines" binding:"required"`
	BaseFrequency     float64                  `json:"base_frequency"`
	BaseVoltage       float64                  `json:"base_voltage"`
	LoadProfile       LoadProfile              `json:"load_profile"`
}

// PowerPlantConfig represents a power plant configuration
type PowerPlantConfig struct {
	ID              string   `json:"id" binding:"required"`
	Name            string   `json:"name" binding:"required"`
	Type            string   `json:"type" binding:"required"`
	MaxCapacityMW   float64  `json:"max_capacity_mw" binding:"required"`
	CurrentOutputMW float64  `json:"current_output_mw"`
	Efficiency      float64  `json:"efficiency"`
	Location        Location `json:"location" binding:"required"`
	IsOperational   bool     `json:"is_operational"`
}

// TransmissionLineConfig represents a transmission line configuration
type TransmissionLineConfig struct {
	ID              string  `json:"id" binding:"required"`
	FromNode        string  `json:"from_node" binding:"required"`
	ToNode          string  `json:"to_node" binding:"required"`
	CapacityMW      float64 `json:"capacity_mw" binding:"required"`
	LengthKM        float64 `json:"length_km" binding:"required"`
	ResistancePerKM float64 `json:"resistance_per_km"`
	ReactancePerKM  float64 `json:"reactance_per_km"`
	IsOperational   bool    `json:"is_operational"`
}

// LoadProfile represents the load profile configuration
type LoadProfile struct {
	BaseLoadMW      float64 `json:"base_load_mw" binding:"required"`
	PeakMultiplier  float64 `json:"peak_multiplier"`
	DailyVariation  float64 `json:"daily_variation"`
	RandomVariation float64 `json:"random_variation"`
}

// Location represents a geographical location
type Location struct {
	X    float64 `json:"x" binding:"required"`
	Y    float64 `json:"y" binding:"required"`
	Name string  `json:"name" binding:"required"`
}

// SimulationResponse represents a simulation response
type SimulationResponse struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Description string                 `json:"description"`
	Status      string                 `json:"status"`
	Config      SimulationConfig       `json:"config"`
	Tags        []string               `json:"tags"`
	Metadata    map[string]interface{} `json:"metadata"`
	CreatedAt   string                 `json:"created_at"`
	UpdatedAt   string                 `json:"updated_at"`
}

// createSimulation handles simulation creation requests
func (s *Server) createSimulation(c *gin.Context) {
	var req CreateSimulationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		s.handleError(c, err, http.StatusBadRequest)
		return
	}

	logrus.WithFields(logrus.Fields{
		"name":         req.Name,
		"plants_count": len(req.Config.PowerPlants),
		"lines_count":  len(req.Config.TransmissionLines),
	}).Info("Creating new simulation")

	// Convert API config to orchestration config
	orchConfig := orchestration.SimulationConfig{
		PowerPlants:      convertPowerPlants(req.Config.PowerPlants),
		TransmissionLines: convertTransmissionLines(req.Config.TransmissionLines),
		BaseFrequency:    req.Config.BaseFrequency,
		BaseVoltage:      req.Config.BaseVoltage,
		LoadProfile:      convertLoadProfile(req.Config.LoadProfile),
	}
	
	// Create simulation through orchestrator
	simulation, err := s.orchestrator.CreateSimulation(req.Name, req.Description, orchConfig, req.Tags, req.Metadata)
	if err != nil {
		s.handleError(c, err, http.StatusInternalServerError)
		return
	}

	response := SimulationResponse{
		ID:          simulation.ID,
		Name:        simulation.Name,
		Description: simulation.Description,
		Status:      simulation.Status.String(),
		Config:      convertOrchConfigToAPI(simulation.Config),
		Tags:        simulation.Tags,
		Metadata:    simulation.Metadata,
		CreatedAt:   simulation.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:   simulation.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}

	s.handleSuccess(c, response, "Simulation created successfully")
}

// listSimulations handles simulation listing requests
func (s *Server) listSimulations(c *gin.Context) {
	// Parse query parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	status := c.Query("status")
	tags := c.QueryArray("tags")

	logrus.WithFields(logrus.Fields{
		"page":   page,
		"limit":  limit,
		"status": status,
		"tags":   tags,
	}).Debug("Listing simulations")

	// Get simulations from orchestrator
	simulations, total, err := s.orchestrator.ListSimulations(page, limit, status, tags)
	if err != nil {
		s.handleError(c, err, http.StatusInternalServerError)
		return
	}

	// Convert to response format
	response := make([]SimulationResponse, len(simulations))
	for i, sim := range simulations {
		response[i] = SimulationResponse{
			ID:          sim.ID,
			Name:        sim.Name,
			Description: sim.Description,
			Status:      sim.Status.String(),
			Config:      convertOrchConfigToAPI(sim.Config),
			Tags:        sim.Tags,
			Metadata:    sim.Metadata,
			CreatedAt:   sim.CreatedAt.Format("2006-01-02T15:04:05Z"),
			UpdatedAt:   sim.UpdatedAt.Format("2006-01-02T15:04:05Z"),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
		"pagination": gin.H{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	})
}

// getSimulation handles single simulation retrieval requests
func (s *Server) getSimulation(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		s.handleError(c, errors.New("invalid parameter"), http.StatusBadRequest)
		return
	}

	logrus.WithField("simulation_id", id).Debug("Getting simulation")

	simulation, err := s.orchestrator.GetSimulation(id)
	if err != nil {
		if err == orchestration.ErrSimulationNotFound {
			s.handleError(c, err, http.StatusNotFound)
		} else {
			s.handleError(c, err, http.StatusInternalServerError)
		}
		return
	}

	response := SimulationResponse{
		ID:          simulation.ID,
		Name:        simulation.Name,
		Description: simulation.Description,
		Status:      simulation.Status.String(),
		Config:      convertOrchConfigToAPI(simulation.Config),
		Tags:        simulation.Tags,
		Metadata:    simulation.Metadata,
		CreatedAt:   simulation.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:   simulation.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}

	s.handleSuccess(c, response, "Simulation retrieved successfully")
}

// deleteSimulation handles simulation deletion requests
func (s *Server) deleteSimulation(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		s.handleError(c, errors.New("invalid parameter"), http.StatusBadRequest)
		return
	}

	logrus.WithField("simulation_id", id).Info("Deleting simulation")

	err := s.orchestrator.DeleteSimulation(id)
	if err != nil {
		if err == orchestration.ErrSimulationNotFound {
			s.handleError(c, err, http.StatusNotFound)
		} else {
			s.handleError(c, err, http.StatusInternalServerError)
		}
		return
	}

	s.handleSuccess(c, nil, "Simulation deleted successfully")
}

// startSimulation handles simulation start requests
func (s *Server) startSimulation(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		s.handleError(c, errors.New("invalid parameter"), http.StatusBadRequest)
		return
	}

	logrus.WithField("simulation_id", id).Info("Starting simulation")

	err := s.orchestrator.StartSimulation(id)
	if err != nil {
		if err == orchestration.ErrSimulationNotFound {
			s.handleError(c, err, http.StatusNotFound)
		} else {
			s.handleError(c, err, http.StatusInternalServerError)
		}
		return
	}

	s.handleSuccess(c, nil, "Simulation started successfully")
}

// stopSimulation handles simulation stop requests
func (s *Server) stopSimulation(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		s.handleError(c, errors.New("invalid parameter"), http.StatusBadRequest)
		return
	}

	logrus.WithField("simulation_id", id).Info("Stopping simulation")

	err := s.orchestrator.StopSimulation(id)
	if err != nil {
		if err == orchestration.ErrSimulationNotFound {
			s.handleError(c, err, http.StatusNotFound)
		} else {
			s.handleError(c, err, http.StatusInternalServerError)
		}
		return
	}

	s.handleSuccess(c, nil, "Simulation stopped successfully")
}

// pauseSimulation handles simulation pause requests
func (s *Server) pauseSimulation(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		s.handleError(c, errors.New("invalid parameter"), http.StatusBadRequest)
		return
	}

	logrus.WithField("simulation_id", id).Info("Pausing simulation")

	err := s.orchestrator.PauseSimulation(id)
	if err != nil {
		if err == orchestration.ErrSimulationNotFound {
			s.handleError(c, err, http.StatusNotFound)
		} else {
			s.handleError(c, err, http.StatusInternalServerError)
		}
		return
	}

	s.handleSuccess(c, nil, "Simulation paused successfully")
}

// Conversion functions between API and orchestration types

func convertPowerPlants(apiPlants []PowerPlantConfig) []orchestration.PowerPlantConfig {
	orchPlants := make([]orchestration.PowerPlantConfig, len(apiPlants))
	for i, plant := range apiPlants {
		orchPlants[i] = orchestration.PowerPlantConfig{
			ID:             plant.ID,
			Name:           plant.Name,
			Type:           plant.Type,
			MaxCapacityMW:  plant.MaxCapacityMW,
			CurrentOutputMW: plant.CurrentOutputMW,
			Efficiency:     plant.Efficiency,
			Location:       orchestration.Location{
				X:    plant.Location.X,
				Y:    plant.Location.Y,
				Name: plant.Location.Name,
			},
			IsOperational:  plant.IsOperational,
		}
	}
	return orchPlants
}

func convertTransmissionLines(apiLines []TransmissionLineConfig) []orchestration.TransmissionLineConfig {
	orchLines := make([]orchestration.TransmissionLineConfig, len(apiLines))
	for i, line := range apiLines {
		orchLines[i] = orchestration.TransmissionLineConfig{
			ID:              line.ID,
			FromNode:        line.FromNode,
			ToNode:          line.ToNode,
			CapacityMW:      line.CapacityMW,
			LengthKM:        line.LengthKM,
			ResistancePerKM: line.ResistancePerKM,
			ReactancePerKM:  line.ReactancePerKM,
			IsOperational:   line.IsOperational,
		}
	}
	return orchLines
}

func convertLoadProfile(apiProfile LoadProfile) orchestration.LoadProfile {
	return orchestration.LoadProfile{
		BaseLoadMW:       apiProfile.BaseLoadMW,
		PeakMultiplier:   apiProfile.PeakMultiplier,
		DailyVariation:   apiProfile.DailyVariation,
		RandomVariation:  apiProfile.RandomVariation,
	}
}

func convertOrchConfigToAPI(orchConfig orchestration.SimulationConfig) SimulationConfig {
	return SimulationConfig{
		PowerPlants:      convertOrchPowerPlantsToAPI(orchConfig.PowerPlants),
		TransmissionLines: convertOrchTransmissionLinesToAPI(orchConfig.TransmissionLines),
		BaseFrequency:    orchConfig.BaseFrequency,
		BaseVoltage:      orchConfig.BaseVoltage,
		LoadProfile:      convertOrchLoadProfileToAPI(orchConfig.LoadProfile),
	}
}

func convertOrchPowerPlantsToAPI(orchPlants []orchestration.PowerPlantConfig) []PowerPlantConfig {
	apiPlants := make([]PowerPlantConfig, len(orchPlants))
	for i, plant := range orchPlants {
		apiPlants[i] = PowerPlantConfig{
			ID:             plant.ID,
			Name:           plant.Name,
			Type:           plant.Type,
			MaxCapacityMW:  plant.MaxCapacityMW,
			CurrentOutputMW: plant.CurrentOutputMW,
			Efficiency:     plant.Efficiency,
			Location:       Location{
				X:    plant.Location.X,
				Y:    plant.Location.Y,
				Name: plant.Location.Name,
			},
			IsOperational:  plant.IsOperational,
		}
	}
	return apiPlants
}

func convertOrchTransmissionLinesToAPI(orchLines []orchestration.TransmissionLineConfig) []TransmissionLineConfig {
	apiLines := make([]TransmissionLineConfig, len(orchLines))
	for i, line := range orchLines {
		apiLines[i] = TransmissionLineConfig{
			ID:              line.ID,
			FromNode:        line.FromNode,
			ToNode:          line.ToNode,
			CapacityMW:      line.CapacityMW,
			LengthKM:        line.LengthKM,
			ResistancePerKM: line.ResistancePerKM,
			ReactancePerKM:  line.ReactancePerKM,
			IsOperational:   line.IsOperational,
		}
	}
	return apiLines
}

func convertOrchLoadProfileToAPI(orchProfile orchestration.LoadProfile) LoadProfile {
	return LoadProfile{
		BaseLoadMW:       orchProfile.BaseLoadMW,
		PeakMultiplier:   orchProfile.PeakMultiplier,
		DailyVariation:   orchProfile.DailyVariation,
		RandomVariation:  orchProfile.RandomVariation,
	}
}
