package database

import (
	"fmt"
	"time"

	"github.com/sirupsen/logrus"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"
)

// logrusWriter implements gormlogger.Writer for GORM logger
type logrusWriter struct {
	logger *logrus.Logger
}

func (w *logrusWriter) Printf(format string, args ...interface{}) {
	w.logger.Infof(format, args...)
}

// Config holds database configuration
type Config struct {
	Host         string        `mapstructure:"host"`
	Port         int           `mapstructure:"port"`
	User         string        `mapstructure:"user"`
	Password     string        `mapstructure:"password"`
	Database     string        `mapstructure:"database"`
	SSLMode      string        `mapstructure:"ssl_mode"`
	MaxOpenConns int           `mapstructure:"max_open_conns"`
	MaxIdleConns int           `mapstructure:"max_idle_conns"`
	MaxLifetime  time.Duration `mapstructure:"max_lifetime"`
	MaxIdleTime  time.Duration `mapstructure:"max_idle_time"`
}

// DefaultConfig returns default database configuration
func DefaultConfig() Config {
	return Config{
		Host:         "localhost",
		Port:         26257,
		User:         "voltedge",
		Password:     "voltedge_password",
		Database:     "voltedge",
		SSLMode:      "disable",
		MaxOpenConns: 25,
		MaxIdleConns: 5,
		MaxLifetime:  time.Hour,
		MaxIdleTime:  time.Minute * 30,
	}
}

// Connection wraps GORM database connection with additional functionality
type Connection struct {
	DB     *gorm.DB
	config Config
	logger *logrus.Logger
}

// NewConnection creates a new database connection
func NewConnection(config Config, logger *logrus.Logger) (*Connection, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		config.Host,
		config.Port,
		config.User,
		config.Password,
		config.Database,
		config.SSLMode,
	)

	// Configure GORM logger
	var gormLogger gormlogger.Interface
	if logger != nil {
		// Use a simple GORM logger that outputs to logrus
		gormLogger = gormlogger.New(
			&logrusWriter{logger: logger},
			gormlogger.Config{
				SlowThreshold:             time.Second,
				LogLevel:                  gormlogger.Info,
				IgnoreRecordNotFoundError: true,
				Colorful:                  false,
			},
		)
	} else {
		gormLogger = gormlogger.Default.LogMode(gormlogger.Info)
	}

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: gormLogger,
		NowFunc: func() time.Time {
			return time.Now().UTC()
		},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("failed to get underlying sql.DB: %w", err)
	}

	// Configure connection pool
	sqlDB.SetMaxOpenConns(config.MaxOpenConns)
	sqlDB.SetMaxIdleConns(config.MaxIdleConns)
	sqlDB.SetConnMaxLifetime(config.MaxLifetime)
	sqlDB.SetConnMaxIdleTime(config.MaxIdleTime)

	conn := &Connection{
		DB:     db,
		config: config,
		logger: logger,
	}

	return conn, nil
}

// Migrate runs database migrations
func (c *Connection) Migrate() error {
	if c.logger != nil {
		c.logger.Info("Running database migrations...")
	}

	err := c.DB.AutoMigrate(
		&User{},
		&Organization{},
		&Simulation{},
		&PowerPlant{},
		&TransmissionLine{},
		&SimulationResult{},
		&ComponentMetric{},
		&FaultEvent{},
		&Alert{},
	)
	if err != nil {
		return fmt.Errorf("failed to migrate database: %w", err)
	}

	if c.logger != nil {
		c.logger.Info("Database migrations completed successfully")
	}

	return nil
}

// Health checks database connectivity
func (c *Connection) Health() error {
	sqlDB, err := c.DB.DB()
	if err != nil {
		return fmt.Errorf("failed to get underlying sql.DB: %w", err)
	}

	return sqlDB.Ping()
}

// Close closes the database connection
func (c *Connection) Close() error {
	sqlDB, err := c.DB.DB()
	if err != nil {
		return fmt.Errorf("failed to get underlying sql.DB: %w", err)
	}

	return sqlDB.Close()
}

// Transaction executes a function within a database transaction
func (c *Connection) Transaction(fn func(*gorm.DB) error) error {
	return c.DB.Transaction(fn)
}

// GetStats returns database connection statistics
func (c *Connection) GetStats() map[string]interface{} {
	sqlDB, err := c.DB.DB()
	if err != nil {
		return map[string]interface{}{
			"error": err.Error(),
		}
	}

	stats := sqlDB.Stats()
	return map[string]interface{}{
		"max_open_connections": stats.MaxOpenConnections,
		"open_connections":     stats.OpenConnections,
		"in_use":               stats.InUse,
		"idle":                 stats.Idle,
		"wait_count":           stats.WaitCount,
		"wait_duration":        stats.WaitDuration.String(),
		"max_idle_closed":      stats.MaxIdleClosed,
		"max_idle_time_closed": stats.MaxIdleTimeClosed,
		"max_lifetime_closed":  stats.MaxLifetimeClosed,
	}
}

// Repository provides common database operations
type Repository struct {
	db     *gorm.DB
	logger *logrus.Logger
}

// NewRepository creates a new repository
func NewRepository(conn *Connection) *Repository {
	return &Repository{
		db:     conn.DB,
		logger: conn.logger,
	}
}

// Create creates a new record
func (r *Repository) Create(model interface{}) error {
	result := r.db.Create(model)
	if result.Error != nil {
		if r.logger != nil {
			r.logger.WithError(result.Error).Error("Failed to create record")
		}
		return result.Error
	}
	return nil
}

// FindByID finds a record by ID
func (r *Repository) FindByID(model interface{}, id interface{}) error {
	result := r.db.First(model, id)
	if result.Error != nil {
		if r.logger != nil {
			r.logger.WithError(result.Error).Error("Failed to find record by ID")
		}
		return result.Error
	}
	return nil
}

// Update updates a record
func (r *Repository) Update(model interface{}) error {
	result := r.db.Save(model)
	if result.Error != nil {
		if r.logger != nil {
			r.logger.WithError(result.Error).Error("Failed to update record")
		}
		return result.Error
	}
	return nil
}

// Delete deletes a record
func (r *Repository) Delete(model interface{}, id interface{}) error {
	result := r.db.Delete(model, id)
	if result.Error != nil {
		if r.logger != nil {
			r.logger.WithError(result.Error).Error("Failed to delete record")
		}
		return result.Error
	}
	return nil
}

// FindAll finds all records with pagination
func (r *Repository) FindAll(model interface{}, limit, offset int) error {
	result := r.db.Limit(limit).Offset(offset).Find(model)
	if result.Error != nil {
		if r.logger != nil {
			r.logger.WithError(result.Error).Error("Failed to find all records")
		}
		return result.Error
	}
	return nil
}

// Count counts records
func (r *Repository) Count(model interface{}) (int64, error) {
	var count int64
	result := r.db.Model(model).Count(&count)
	if result.Error != nil {
		if r.logger != nil {
			r.logger.WithError(result.Error).Error("Failed to count records")
		}
		return 0, result.Error
	}
	return count, nil
}
