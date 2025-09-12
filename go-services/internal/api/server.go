package api

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"

	"voltedge/go-services/internal/config"
	"voltedge/go-services/internal/database"
	"voltedge/go-services/internal/grpc"
	"voltedge/go-services/internal/observability"
	"voltedge/go-services/internal/orchestration"
)

// Server represents the API server
type Server struct {
	config            *config.APIConfig
	orchestrator      *orchestration.Orchestrator
	grpcClient        *grpc.Client
	simulationService *database.SimulationService
	router            *gin.Engine
}

// NewServer creates a new API server
func NewServer(cfg *config.APIConfig, orchestrator *orchestration.Orchestrator, grpcClient *grpc.Client, simulationService *database.SimulationService) *Server {
	server := &Server{
		config:            cfg,
		orchestrator:      orchestrator,
		grpcClient:        grpcClient,
		simulationService: simulationService,
	}

	server.setupRouter()
	return server
}

// setupRouter configures the Gin router
func (s *Server) setupRouter() {
	// Set Gin mode
	if gin.Mode() == gin.ReleaseMode {
		gin.SetMode(gin.ReleaseMode)
	}

	s.router = gin.New()

	// Add middleware
	s.router.Use(gin.LoggerWithFormatter(s.loggerFormatter))
	s.router.Use(gin.Recovery())
	s.router.Use(s.metricsMiddleware())
	s.router.Use(s.corsMiddleware())

	// Add routes
	s.setupRoutes()
}

// setupRoutes configures all API routes
func (s *Server) setupRoutes() {
	// Health check endpoint
	s.router.GET("/health", s.healthCheck)

	// API v1 routes
	v1 := s.router.Group("/api/v1")
	{
		// Simulation management
		simulations := v1.Group("/simulations")
		{
			simulations.POST("", s.createSimulation)
			simulations.GET("", s.listSimulations)
			simulations.GET("/:id", s.getSimulation)
			simulations.DELETE("/:id", s.deleteSimulation)
			simulations.POST("/:id/start", s.startSimulation)
			simulations.POST("/:id/stop", s.stopSimulation)
			simulations.POST("/:id/pause", s.pauseSimulation)
		}

		// Grid management
		grid := v1.Group("/grid")
		{
			grid.GET("/state/:simulation_id", s.getGridState)
			grid.GET("/components/:simulation_id", s.getGridComponents)
			grid.POST("/failures/:simulation_id", s.injectFailure)
		}

		// Power plants
		plants := v1.Group("/plants")
		{
			plants.GET("", s.listPowerPlants)
			plants.GET("/:id", s.getPowerPlant)
			plants.POST("/:id/control", s.controlPowerPlant)
		}

		// Transmission lines
		lines := v1.Group("/transmission")
		{
			lines.GET("", s.listTransmissionLines)
			lines.GET("/:id", s.getTransmissionLine)
			lines.POST("/:id/control", s.controlTransmissionLine)
		}

		// Analytics and metrics
		analytics := v1.Group("/analytics")
		{
			analytics.GET("/performance/:simulation_id", s.getPerformanceMetrics)
			analytics.GET("/history/:simulation_id", s.getSimulationHistory)
			analytics.GET("/predictions/:simulation_id", s.getPredictions)
		}

		// Real-time data streaming
		stream := v1.Group("/stream")
		{
			stream.GET("/simulation/:id", s.streamSimulationData)
			stream.GET("/grid/:id", s.streamGridData)
		}
	}

	// WebSocket endpoint
	s.router.GET(s.config.WebSocketPath, s.handleWebSocket)

	// Static file serving for documentation
	s.router.Static("/docs", "./docs")
	s.router.GET("/", func(c *gin.Context) {
		c.Redirect(http.StatusMovedPermanently, "/docs")
	})
}

// Handler returns the HTTP handler
func (s *Server) Handler() http.Handler {
	return s.router
}

// loggerFormatter provides custom logging format
func (s *Server) loggerFormatter(param gin.LogFormatterParams) string {
	return fmt.Sprintf("%s [%s] %s %s %d %s %s %s\n",
		param.TimeStamp.Format(time.RFC3339),
		param.Method,
		param.Path,
		param.Request.Proto,
		param.StatusCode,
		param.Latency,
		param.ClientIP,
		param.ErrorMessage,
	)
}

// metricsMiddleware adds Prometheus metrics
func (s *Server) metricsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		c.Next()

		duration := time.Since(start)
		observability.RecordHTTPRequest(c.Request.Method, c.Request.URL.Path, fmt.Sprintf("%d", c.Writer.Status()), duration)
	}
}

// corsMiddleware configures CORS
func (s *Server) corsMiddleware() gin.HandlerFunc {
	config := cors.Config{
		AllowOrigins:     s.config.CORSOrigins,
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}

	return cors.New(config)
}

// healthCheck handles health check requests
func (s *Server) healthCheck(c *gin.Context) {
	health := map[string]interface{}{
		"status":    "healthy",
		"timestamp": time.Now().UTC(),
		"version":   "1.0.0",
		"services": map[string]interface{}{
			"orchestrator": s.orchestrator.Health(),
			"grpc_client":  s.grpcClient.Health(),
		},
	}

	// Check if any service is unhealthy
	if !s.orchestrator.Health().IsHealthy || !s.grpcClient.Health().IsHealthy {
		health["status"] = "unhealthy"
		c.JSON(http.StatusServiceUnavailable, health)
		return
	}

	c.JSON(http.StatusOK, health)
}

// ErrorResponse represents an API error response
type ErrorResponse struct {
	Error   string                 `json:"error"`
	Message string                 `json:"message"`
	Code    string                 `json:"code,omitempty"`
	Details map[string]interface{} `json:"details,omitempty"`
}

// SuccessResponse represents a successful API response
type SuccessResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data"`
	Message string      `json:"message,omitempty"`
}

// handleError handles API errors consistently
func (s *Server) handleError(c *gin.Context, err error, statusCode int) {
	logrus.WithError(err).WithField("path", c.Request.URL.Path).Error("API error")

	response := ErrorResponse{
		Error:   http.StatusText(statusCode),
		Message: err.Error(),
		Code:    "API_ERROR",
	}

	c.JSON(statusCode, response)
}

// handleSuccess handles successful API responses consistently
func (s *Server) handleSuccess(c *gin.Context, data interface{}, message string) {
	response := SuccessResponse{
		Success: true,
		Data:    data,
		Message: message,
	}

	c.JSON(http.StatusOK, response)
}
