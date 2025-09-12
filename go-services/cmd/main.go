package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"voltedge/go-services/internal/api"
	"voltedge/go-services/internal/config"
	"voltedge/go-services/internal/database"
	"voltedge/go-services/internal/grpc"
	"voltedge/go-services/internal/observability"
	"voltedge/go-services/internal/orchestration"

	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	version   = "dev"
	buildTime = "unknown"
	gitCommit = "unknown"
)

func main() {
	var rootCmd = &cobra.Command{
		Use:   "voltedge-api",
		Short: "VoltEdge API Gateway and Microservices",
		Long: `VoltEdge API Gateway provides REST/GraphQL APIs, WebSocket streaming,
observability, and orchestration for the VoltEdge energy grid simulator.`,
		Version: fmt.Sprintf("%s (built %s, commit %s)", version, buildTime, gitCommit),
		RunE:    runServer,
	}

	// Add command line flags
	rootCmd.PersistentFlags().String("config", "", "config file path")
	rootCmd.PersistentFlags().String("log-level", "info", "log level (debug, info, warn, error)")
	rootCmd.PersistentFlags().String("port", "8080", "HTTP server port")
	rootCmd.PersistentFlags().String("grpc-port", "8081", "gRPC server port")
	rootCmd.PersistentFlags().String("metrics-port", "9090", "metrics server port")
	rootCmd.PersistentFlags().String("zig-endpoint", "localhost:9091", "Zig simulation engine endpoint")

	// Bind flags to viper
	viper.BindPFlags(rootCmd.PersistentFlags())

	// Add subcommands
	rootCmd.AddCommand(newVersionCmd())
	rootCmd.AddCommand(newHealthCmd())
	rootCmd.AddCommand(newConfigCmd())

	if err := rootCmd.Execute(); err != nil {
		logrus.Fatal(err)
	}
}

func runServer(cmd *cobra.Command, args []string) error {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	// Set log level
	level, err := logrus.ParseLevel(cfg.Log.Level)
	if err != nil {
		return fmt.Errorf("invalid log level: %w", err)
	}
	logrus.SetLevel(level)
	logrus.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: time.RFC3339,
	})

	logrus.WithFields(logrus.Fields{
		"version":    version,
		"build_time": buildTime,
		"git_commit": gitCommit,
	}).Info("Starting VoltEdge API Gateway")

	// Initialize observability
	observability.Init(&cfg.Observability)

	// Initialize database connection
	dbConfig := database.Config{
		Host:         cfg.Database.Host,
		Port:         cfg.Database.Port,
		User:         cfg.Database.Username,
		Password:     cfg.Database.Password,
		Database:     cfg.Database.Database,
		SSLMode:      cfg.Database.SSLMode,
		MaxOpenConns: cfg.Database.MaxConns,
		MaxIdleConns: cfg.Database.MinConns,
		MaxLifetime:  cfg.Database.MaxLifetime,
		MaxIdleTime:  cfg.Database.MaxIdleTime,
	}

	logger := logrus.New()
	logger.SetLevel(level)
	logger.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: time.RFC3339,
	})

	dbConn, err := database.NewConnection(dbConfig, logger)
	if err != nil {
		logger.WithError(err).Fatal("Failed to connect to database")
	}
	defer dbConn.Close()

	// Run database migrations
	if err := dbConn.Migrate(); err != nil {
		logger.WithError(err).Fatal("Failed to run database migrations")
	}

	// Initialize simulation service
	simulationService := database.NewSimulationService(dbConn.DB, logger)
	defer observability.Shutdown()

	// Create context for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Initialize orchestration service
	orchestrator := orchestration.NewOrchestrator(&cfg.Orchestration)
	if err := orchestrator.Start(ctx); err != nil {
		return fmt.Errorf("failed to start orchestrator: %w", err)
	}
	defer orchestrator.Stop()

	// Initialize gRPC client for Zig communication
	grpcClient, err := grpc.NewClient(cfg.Zig.Endpoint)
	if err != nil {
		return fmt.Errorf("failed to create gRPC client: %w", err)
	}
	defer grpcClient.Close()

	// Initialize API server
	apiServer := api.NewServer(&cfg.API, orchestrator, grpcClient, simulationService)

	// Start HTTP server
	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.API.Port),
		Handler:      apiServer.Handler(),
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Start metrics server
	metricsServer := &http.Server{
		Addr:    fmt.Sprintf(":%s", cfg.Observability.MetricsPort),
		Handler: observability.MetricsHandler(),
	}

	// Start servers in goroutines
	go func() {
		logrus.WithField("port", cfg.API.Port).Info("Starting HTTP server")
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logrus.WithError(err).Fatal("HTTP server failed")
		}
	}()

	go func() {
		logrus.WithField("port", cfg.Observability.MetricsPort).Info("Starting metrics server")
		if err := metricsServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logrus.WithError(err).Error("Metrics server failed")
		}
	}()

	// Wait for interrupt signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	logrus.Info("Shutting down servers...")

	// Graceful shutdown with timeout
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()

	// Shutdown HTTP server
	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		logrus.WithError(err).Error("HTTP server shutdown failed")
	}

	// Shutdown metrics server
	if err := metricsServer.Shutdown(shutdownCtx); err != nil {
		logrus.WithError(err).Error("Metrics server shutdown failed")
	}

	logrus.Info("Servers stopped")
	return nil
}

func newVersionCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print version information",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("VoltEdge API Gateway\n")
			fmt.Printf("Version: %s\n", version)
			fmt.Printf("Build Time: %s\n", buildTime)
			fmt.Printf("Git Commit: %s\n", gitCommit)
		},
	}
}

func newHealthCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "health",
		Short: "Check service health",
		RunE: func(cmd *cobra.Command, args []string) error {
			// TODO: Implement health check logic
			fmt.Println("Health check not implemented yet")
			return nil
		},
	}
}

func newConfigCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "config",
		Short: "Validate configuration",
		RunE: func(cmd *cobra.Command, args []string) error {
			cfg, err := config.Load()
			if err != nil {
				return fmt.Errorf("invalid config: %w", err)
			}

			fmt.Println("Configuration is valid:")
			fmt.Printf("  HTTP Port: %s\n", cfg.API.Port)
			fmt.Printf("  Zig Endpoint: %s\n", cfg.Zig.Endpoint)
			fmt.Printf("  Log Level: %s\n", cfg.Log.Level)

			return nil
		},
	}
}
