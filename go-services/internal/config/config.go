package config

import (
	"fmt"
	"strings"
	"time"

	"github.com/spf13/viper"
)

// Config represents the application configuration
type Config struct {
	API           APIConfig           `mapstructure:"api"`
	Zig           ZigConfig           `mapstructure:"zig"`
	Observability ObservabilityConfig `mapstructure:"observability"`
	Orchestration OrchestrationConfig `mapstructure:"orchestration"`
	Database      DatabaseConfig      `mapstructure:"database"`
	Cache         CacheConfig         `mapstructure:"cache"`
	Log           LogConfig           `mapstructure:"log"`
	Security      SecurityConfig      `mapstructure:"security"`
}

// APIConfig holds HTTP API server configuration
type APIConfig struct {
	Port             string        `mapstructure:"port"`
	Host             string        `mapstructure:"host"`
	ReadTimeout      time.Duration `mapstructure:"read_timeout"`
	WriteTimeout     time.Duration `mapstructure:"write_timeout"`
	IdleTimeout      time.Duration `mapstructure:"idle_timeout"`
	MaxHeaderBytes   int           `mapstructure:"max_header_bytes"`
	CORSOrigins      []string      `mapstructure:"cors_origins"`
	RateLimitRPS     int           `mapstructure:"rate_limit_rps"`
	RateLimitBurst   int           `mapstructure:"rate_limit_burst"`
	WebSocketPath    string        `mapstructure:"websocket_path"`
	WebSocketTimeout time.Duration `mapstructure:"websocket_timeout"`
}

// ZigConfig holds Zig simulation engine configuration
type ZigConfig struct {
	Endpoint      string        `mapstructure:"endpoint"`
	Timeout       time.Duration `mapstructure:"timeout"`
	MaxRetries    int           `mapstructure:"max_retries"`
	RetryInterval time.Duration `mapstructure:"retry_interval"`
	KeepAlive     time.Duration `mapstructure:"keep_alive"`
}

// ObservabilityConfig holds monitoring and tracing configuration
type ObservabilityConfig struct {
	MetricsPort      string  `mapstructure:"metrics_port"`
	MetricsPath      string  `mapstructure:"metrics_path"`
	EnablePrometheus bool    `mapstructure:"enable_prometheus"`
	EnableJaeger     bool    `mapstructure:"enable_jaeger"`
	JaegerEndpoint   string  `mapstructure:"jaeger_endpoint"`
	ServiceName      string  `mapstructure:"service_name"`
	SamplingRatio    float64 `mapstructure:"sampling_ratio"`
	HealthCheckPath  string  `mapstructure:"health_check_path"`
	ProfilingEnabled bool    `mapstructure:"profiling_enabled"`
	ProfilingPort    string  `mapstructure:"profiling_port"`
}

// OrchestrationConfig holds job orchestration configuration
type OrchestrationConfig struct {
	MaxConcurrentSimulations int           `mapstructure:"max_concurrent_simulations"`
	SimulationTimeout        time.Duration `mapstructure:"simulation_timeout"`
	CleanupInterval          time.Duration `mapstructure:"cleanup_interval"`
	JobQueueSize             int           `mapstructure:"job_queue_size"`
	WorkerPoolSize           int           `mapstructure:"worker_pool_size"`
	EnableAutoScaling        bool          `mapstructure:"enable_auto_scaling"`
	ScalingThreshold         float64       `mapstructure:"scaling_threshold"`
}

// DatabaseConfig holds database configuration
type DatabaseConfig struct {
	Host         string        `mapstructure:"host"`
	Port         int           `mapstructure:"port"`
	Database     string        `mapstructure:"database"`
	Username     string        `mapstructure:"username"`
	Password     string        `mapstructure:"password"`
	SSLMode      string        `mapstructure:"ssl_mode"`
	MaxConns     int           `mapstructure:"max_conns"`
	MinConns     int           `mapstructure:"min_conns"`
	MaxLifetime  time.Duration `mapstructure:"max_lifetime"`
	MaxIdleTime  time.Duration `mapstructure:"max_idle_time"`
	QueryTimeout time.Duration `mapstructure:"query_timeout"`
}

// CacheConfig holds cache configuration
type CacheConfig struct {
	Type       string        `mapstructure:"type"`
	Host       string        `mapstructure:"host"`
	Port       int           `mapstructure:"port"`
	Password   string        `mapstructure:"password"`
	Database   int           `mapstructure:"database"`
	TTL        time.Duration `mapstructure:"ttl"`
	MaxRetries int           `mapstructure:"max_retries"`
	PoolSize   int           `mapstructure:"pool_size"`
}

// LogConfig holds logging configuration
type LogConfig struct {
	Level      string `mapstructure:"level"`
	Format     string `mapstructure:"format"`
	Output     string `mapstructure:"output"`
	MaxSize    int    `mapstructure:"max_size"`
	MaxAge     int    `mapstructure:"max_age"`
	MaxBackups int    `mapstructure:"max_backups"`
	Compress   bool   `mapstructure:"compress"`
}

// SecurityConfig holds security configuration
type SecurityConfig struct {
	JWTSecret       string        `mapstructure:"jwt_secret"`
	JWTExpiry       time.Duration `mapstructure:"jwt_expiry"`
	RefreshExpiry   time.Duration `mapstructure:"refresh_expiry"`
	EnableHTTPS     bool          `mapstructure:"enable_https"`
	CertFile        string        `mapstructure:"cert_file"`
	KeyFile         string        `mapstructure:"key_file"`
	EnableRateLimit bool          `mapstructure:"enable_rate_limit"`
	TrustedProxies  []string      `mapstructure:"trusted_proxies"`
	EnableCORS      bool          `mapstructure:"enable_cors"`
}

// Load loads configuration from file and environment variables
func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./configs")
	viper.AddConfigPath("/etc/voltedge")

	// Set defaults
	setDefaults()

	// Enable reading from environment variables
	viper.AutomaticEnv()
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))

	// Read config file (optional)
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Validate configuration
	if err := config.Validate(); err != nil {
		return nil, fmt.Errorf("config validation failed: %w", err)
	}

	return &config, nil
}

// setDefaults sets default configuration values
func setDefaults() {
	// API defaults
	viper.SetDefault("api.port", "8080")
	viper.SetDefault("api.host", "0.0.0.0")
	viper.SetDefault("api.read_timeout", "30s")
	viper.SetDefault("api.write_timeout", "30s")
	viper.SetDefault("api.idle_timeout", "120s")
	viper.SetDefault("api.max_header_bytes", 1048576) // 1MB
	viper.SetDefault("api.cors_origins", []string{"*"})
	viper.SetDefault("api.rate_limit_rps", 100)
	viper.SetDefault("api.rate_limit_burst", 200)
	viper.SetDefault("api.websocket_path", "/ws")
	viper.SetDefault("api.websocket_timeout", "60s")

	// Zig defaults
	viper.SetDefault("zig.endpoint", "localhost:9091")
	viper.SetDefault("zig.timeout", "30s")
	viper.SetDefault("zig.max_retries", 3)
	viper.SetDefault("zig.retry_interval", "5s")
	viper.SetDefault("zig.keep_alive", "30s")

	// Observability defaults
	viper.SetDefault("observability.metrics_port", "9090")
	viper.SetDefault("observability.metrics_path", "/metrics")
	viper.SetDefault("observability.enable_prometheus", true)
	viper.SetDefault("observability.enable_jaeger", false)
	viper.SetDefault("observability.jaeger_endpoint", "http://localhost:14268/api/traces")
	viper.SetDefault("observability.service_name", "voltedge-api")
	viper.SetDefault("observability.sampling_ratio", 0.1)
	viper.SetDefault("observability.health_check_path", "/health")
	viper.SetDefault("observability.profiling_enabled", false)
	viper.SetDefault("observability.profiling_port", "6060")

	// Orchestration defaults
	viper.SetDefault("orchestration.max_concurrent_simulations", 10)
	viper.SetDefault("orchestration.simulation_timeout", "10m")
	viper.SetDefault("orchestration.cleanup_interval", "5m")
	viper.SetDefault("orchestration.job_queue_size", 1000)
	viper.SetDefault("orchestration.worker_pool_size", 5)
	viper.SetDefault("orchestration.enable_auto_scaling", true)
	viper.SetDefault("orchestration.scaling_threshold", 0.8)

	// Database defaults (CockroachDB)
	viper.SetDefault("database.host", "cockroachdb")
	viper.SetDefault("database.port", 26257)
	viper.SetDefault("database.database", "voltedge")
	viper.SetDefault("database.username", "voltedge")
	viper.SetDefault("database.password", "voltedge_password")
	viper.SetDefault("database.ssl_mode", "disable")
	viper.SetDefault("database.max_conns", 25)
	viper.SetDefault("database.min_conns", 5)
	viper.SetDefault("database.max_lifetime", "5m")
	viper.SetDefault("database.max_idle_time", "1m")
	viper.SetDefault("database.query_timeout", "30s")

	// Cache defaults
	viper.SetDefault("cache.type", "redis")
	viper.SetDefault("cache.host", "localhost")
	viper.SetDefault("cache.port", 6379)
	viper.SetDefault("cache.password", "")
	viper.SetDefault("cache.database", 0)
	viper.SetDefault("cache.ttl", "1h")
	viper.SetDefault("cache.max_retries", 3)
	viper.SetDefault("cache.pool_size", 10)

	// Log defaults
	viper.SetDefault("log.level", "info")
	viper.SetDefault("log.format", "json")
	viper.SetDefault("log.output", "stdout")
	viper.SetDefault("log.max_size", 100) // MB
	viper.SetDefault("log.max_age", 30)   // days
	viper.SetDefault("log.max_backups", 3)
	viper.SetDefault("log.compress", true)

	// Security defaults
	viper.SetDefault("security.jwt_secret", "voltedge-secret-key-change-in-production")
	viper.SetDefault("security.jwt_expiry", "1h")
	viper.SetDefault("security.refresh_expiry", "24h")
	viper.SetDefault("security.enable_https", false)
	viper.SetDefault("security.cert_file", "")
	viper.SetDefault("security.key_file", "")
	viper.SetDefault("security.enable_rate_limit", true)
	viper.SetDefault("security.trusted_proxies", []string{})
	viper.SetDefault("security.enable_cors", true)
}

// Validate validates the configuration
func (c *Config) Validate() error {
	if c.API.Port == "" {
		return fmt.Errorf("api.port is required")
	}

	if c.Zig.Endpoint == "" {
		return fmt.Errorf("zig.endpoint is required")
	}

	if c.Observability.ServiceName == "" {
		return fmt.Errorf("observability.service_name is required")
	}

	if c.Security.EnableHTTPS && (c.Security.CertFile == "" || c.Security.KeyFile == "") {
		return fmt.Errorf("cert_file and key_file are required when HTTPS is enabled")
	}

	return nil
}
