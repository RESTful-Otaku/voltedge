package observability

import (
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/sirupsen/logrus"

	"voltedge/go-services/internal/config"
)

var (
	// HTTP metrics
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "voltedge_http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "voltedge_http_request_duration_seconds",
			Help:    "HTTP request duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)

	// Simulation metrics
	simulationsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "voltedge_simulations_total",
			Help: "Total number of simulations",
		},
		[]string{"status"},
	)

	simulationsActive = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "voltedge_simulations_active",
			Help: "Number of active simulations",
		},
	)

	simulationDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "voltedge_simulation_duration_seconds",
			Help:    "Simulation duration in seconds",
			Buckets: []float64{1, 5, 10, 30, 60, 300, 600, 1800, 3600, 7200, 14400},
		},
		[]string{"simulation_id"},
	)

	// Grid metrics
	gridGenerationTotal = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "voltedge_grid_generation_mw",
			Help: "Total power generation in MW",
		},
		[]string{"simulation_id"},
	)

	gridConsumptionTotal = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "voltedge_grid_consumption_mw",
			Help: "Total power consumption in MW",
		},
		[]string{"simulation_id"},
	)

	gridFrequency = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "voltedge_grid_frequency_hz",
			Help: "Grid frequency in Hz",
		},
		[]string{"simulation_id"},
	)

	gridFailures = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "voltedge_grid_failures_total",
			Help: "Total number of grid failures",
		},
		[]string{"simulation_id", "failure_type"},
	)

	// Power plant metrics
	powerPlantOutput = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "voltedge_power_plant_output_mw",
			Help: "Power plant output in MW",
		},
		[]string{"simulation_id", "plant_id", "plant_type"},
	)

	powerPlantEfficiency = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "voltedge_power_plant_efficiency_ratio",
			Help: "Power plant efficiency ratio",
		},
		[]string{"simulation_id", "plant_id", "plant_type"},
	)

	powerPlantCO2Emissions = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "voltedge_power_plant_co2_emissions_kg_hour",
			Help: "Power plant CO2 emissions in kg/hour",
		},
		[]string{"simulation_id", "plant_id", "plant_type"},
	)

	// Transmission line metrics
	transmissionLineFlow = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "voltedge_transmission_line_flow_mw",
			Help: "Transmission line power flow in MW",
		},
		[]string{"simulation_id", "line_id"},
	)

	transmissionLineUtilization = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "voltedge_transmission_line_utilization_ratio",
			Help: "Transmission line utilization ratio",
		},
		[]string{"simulation_id", "line_id"},
	)

	transmissionLineLosses = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "voltedge_transmission_line_losses_mw",
			Help: "Transmission line power losses in MW",
		},
		[]string{"simulation_id", "line_id"},
	)

	// System metrics
	systemMemoryUsage = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "voltedge_system_memory_usage_bytes",
			Help: "System memory usage in bytes",
		},
	)

	systemCPUUsage = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "voltedge_system_cpu_usage_percent",
			Help: "System CPU usage percentage",
		},
	)

	// gRPC metrics
	grpcRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "voltedge_grpc_requests_total",
			Help: "Total number of gRPC requests",
		},
		[]string{"method", "status"},
	)

	grpcRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "voltedge_grpc_request_duration_seconds",
			Help:    "gRPC request duration in seconds",
			Buckets: []float64{0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10},
		},
		[]string{"method"},
	)

	grpcConnectionsActive = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "voltedge_grpc_connections_active",
			Help: "Number of active gRPC connections",
		},
	)
)

// Config holds observability configuration
type Config struct {
	*config.ObservabilityConfig
}

// Init initializes observability components
func Init(cfg *config.ObservabilityConfig) {
	logrus.Info("Initializing observability components")

	// Initialize tracing if enabled
	if cfg.EnableJaeger {
		initTracing(cfg)
	}

	// Initialize custom metrics
	initCustomMetrics()

	logrus.Info("Observability components initialized")
}

// Shutdown shuts down observability components
func Shutdown() {
	logrus.Info("Shutting down observability components")
	shutdownTracing()
	logrus.Info("Observability components shut down")
}

// MetricsHandler returns the Prometheus metrics handler
func MetricsHandler() http.Handler {
	return promhttp.Handler()
}

// RecordHTTPRequest records HTTP request metrics
func RecordHTTPRequest(method, endpoint, status string, duration time.Duration) {
	httpRequestsTotal.WithLabelValues(method, endpoint, status).Inc()
	httpRequestDuration.WithLabelValues(method, endpoint).Observe(duration.Seconds())
}

// RecordSimulationStart records simulation start metrics
func RecordSimulationStart(simulationID string) {
	simulationsTotal.WithLabelValues("started").Inc()
	simulationsActive.Inc()
}

// RecordSimulationStop records simulation stop metrics
func RecordSimulationStop(simulationID string, duration time.Duration) {
	simulationsTotal.WithLabelValues("stopped").Inc()
	simulationsActive.Dec()
	simulationDuration.WithLabelValues(simulationID).Observe(duration.Seconds())
}

// RecordSimulationError records simulation error metrics
func RecordSimulationError(simulationID string) {
	simulationsTotal.WithLabelValues("error").Inc()
	simulationsActive.Dec()
}

// RecordGridState records grid state metrics
func RecordGridState(simulationID string, generation, consumption, frequency float64) {
	gridGenerationTotal.WithLabelValues(simulationID).Set(generation)
	gridConsumptionTotal.WithLabelValues(simulationID).Set(consumption)
	gridFrequency.WithLabelValues(simulationID).Set(frequency)
}

// RecordGridFailure records grid failure metrics
func RecordGridFailure(simulationID, failureType string) {
	gridFailures.WithLabelValues(simulationID, failureType).Inc()
}

// RecordPowerPlantMetrics records power plant metrics
func RecordPowerPlantMetrics(simulationID, plantID, plantType string, output, efficiency, co2Emissions float64) {
	powerPlantOutput.WithLabelValues(simulationID, plantID, plantType).Set(output)
	powerPlantEfficiency.WithLabelValues(simulationID, plantID, plantType).Set(efficiency)
	powerPlantCO2Emissions.WithLabelValues(simulationID, plantID, plantType).Set(co2Emissions)
}

// RecordTransmissionLineMetrics records transmission line metrics
func RecordTransmissionLineMetrics(simulationID, lineID string, flow, utilization, losses float64) {
	transmissionLineFlow.WithLabelValues(simulationID, lineID).Set(flow)
	transmissionLineUtilization.WithLabelValues(simulationID, lineID).Set(utilization)
	transmissionLineLosses.WithLabelValues(simulationID, lineID).Set(losses)
}

// RecordSystemMetrics records system metrics
func RecordSystemMetrics(memoryUsage int64, cpuUsage float64) {
	systemMemoryUsage.Set(float64(memoryUsage))
	systemCPUUsage.Set(cpuUsage)
}

// RecordGRPCRequest records gRPC request metrics
func RecordGRPCRequest(method, status string, duration time.Duration) {
	grpcRequestsTotal.WithLabelValues(method, status).Inc()
	grpcRequestDuration.WithLabelValues(method).Observe(duration.Seconds())
}

// RecordGRPCConnection records gRPC connection metrics
func RecordGRPCConnection(connected bool) {
	if connected {
		grpcConnectionsActive.Inc()
	} else {
		grpcConnectionsActive.Dec()
	}
}

// initCustomMetrics initializes custom metrics
func initCustomMetrics() {
	// Register any additional custom metrics here
	logrus.Debug("Custom metrics initialized")
}

// initTracing initializes distributed tracing
func initTracing(cfg *config.ObservabilityConfig) {
	logrus.WithFields(logrus.Fields{
		"jaeger_endpoint": cfg.JaegerEndpoint,
		"service_name":    cfg.ServiceName,
		"sampling_ratio":  cfg.SamplingRatio,
	}).Info("Initializing distributed tracing")

	// TODO: Implement Jaeger tracing setup
	// This would typically involve:
	// 1. Creating Jaeger exporter
	// 2. Setting up trace provider
	// 3. Configuring sampling
	// 4. Adding middleware to HTTP and gRPC handlers
}

// shutdownTracing shuts down tracing components
func shutdownTracing() {
	logrus.Info("Shutting down distributed tracing")
	// TODO: Implement tracing shutdown
}


