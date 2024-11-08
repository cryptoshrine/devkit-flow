use anchor_lang::prelude::*;

/// The main state account for the monitoring system
#[account]
#[derive(Default)]
pub struct MonitoringState {
    /// Authority that can manage the monitoring configuration
    pub authority: Pubkey,
    /// Global monitoring configuration
    pub config: MonitoringConfig,
    /// List of all metric account pubkeys being tracked
    pub metrics: Vec<Pubkey>,
    /// List of all alert configuration pubkeys
    pub alerts: Vec<Pubkey>,
}

impl MonitoringState {
    pub fn validate_config(&self) -> Result<()> {
        require!(
            self.config.max_metrics > 0 && self.config.max_metrics <= 100,
            MonitoringError::InvalidMaxMetrics
        );
        require!(
            self.config.max_alerts > 0 && self.config.max_alerts <= 50,
            MonitoringError::InvalidMaxAlerts
        );
        require!(
            self.config.max_data_points > 0 && self.config.max_data_points <= 1000,
            MonitoringError::InvalidMaxDataPoints
        );
        Ok(())
    }
}

/// Global configuration parameters for the monitoring system
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, Default)]
pub struct MonitoringConfig {
    /// Maximum number of metrics that can be tracked
    pub max_metrics: u16,
    /// Maximum number of alerts that can be configured
    pub max_alerts: u16,
    /// Maximum number of data points stored per metric
    pub max_data_points: u32,
    /// Minimum interval between metric updates in seconds
    pub min_update_interval: i64,
    /// Whether to enforce rate limiting on metric updates
    pub rate_limiting_enabled: bool,
}

/// An individual metric tracking account
#[account]
#[derive(Default)]
pub struct MetricAccount {
    /// Authority allowed to update this metric
    pub authority: Pubkey,
    /// Name/identifier of the metric
    pub name: String,
    /// Metric-specific parameters
    pub params: MetricParams,
    /// Whether the metric is currently enabled
    pub enabled: bool,
    /// Last time the metric was updated (unix timestamp)
    pub last_updated: i64,
    /// Historical data points for this metric
    pub data_points: Vec<MetricDataPoint>,
}

impl MetricAccount {
    pub fn validate_value(&self, value: i64, timestamp: i64) -> Result<()> {
        require!(self.enabled, MonitoringError::MetricDisabled);
        
        // Validate update timing
        require!(
            timestamp > self.last_updated,
            MonitoringError::InvalidTimestamp
        );

        // Validate value is within configured bounds
        if let Some(min) = self.params.min_value {
            require!(
                value >= min,
                MonitoringError::ValueBelowMinimum
            );
        }
        
        if let Some(max) = self.params.max_value {
            require!(
                value <= max,
                MonitoringError::ValueAboveMaximum
            );
        }

        // Validate rate of change if configured
        if let Some(max_change) = self.params.max_rate_of_change {
            if let Some(last_point) = self.data_points.last() {
                let time_diff = timestamp - last_point.timestamp;
                let value_diff = (value - last_point.value).abs();
                let rate = if time_diff > 0 { value_diff as f64 / time_diff as f64 } else { 0.0 };
                
                require!(
                    rate <= max_change as f64,
                    MonitoringError::RateOfChangeExceeded
                );
            }
        }

        Ok(())
    }
}

/// Parameters configuring an individual metric
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, Default)]
pub struct MetricParams {
    /// Optional minimum allowed value
    pub min_value: Option<i64>,
    /// Optional maximum allowed value
    pub max_value: Option<i64>,
    /// Optional maximum rate of change (units per second)
    pub max_rate_of_change: Option<u32>,
    /// Whether to store historical data points
    pub store_history: bool,
    /// Number of data points to retain (up to global max)
    pub retention_period: u32,
}

/// A single data point for a metric
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug)]
pub struct MetricDataPoint {
    /// Unix timestamp when the data point was recorded
    pub timestamp: i64,
    /// The recorded value
    pub value: i64,
}

/// Alert configuration account
#[account]
#[derive(Default)]
pub struct AlertConfig {
    /// Authority allowed to manage this alert
    pub authority: Pubkey,
    /// The metric this alert monitors
    pub metric: Pubkey,
    /// Alert configuration parameters 
    pub params: AlertConfigParams,
    /// Whether the alert is currently enabled
    pub enabled: bool,
    /// Last time the alert was triggered (unix timestamp)
    pub last_triggered: i64,
}

/// Parameters configuring an alert
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, Default)]
pub struct AlertConfigParams {
    /// Threshold type (above/below/change)
    pub threshold_type: AlertThresholdType,
    /// Threshold value that triggers the alert
    pub threshold_value: i64,
    /// Optional secondary threshold for range-based alerts
    pub secondary_threshold: Option<i64>,
    /// Minimum time between alert triggers (seconds)
    pub min_trigger_interval: u32,
    /// Number of consecutive violations before triggering
    pub required_violations: u8,
    /// Optional webhook URL for notifications
    pub webhook_url: Option<String>,
}

/// Types of alert thresholds
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, Default, PartialEq)]
pub enum AlertThresholdType {
    #[default]
    Above,
    Below,
    Change,
    Range,
}

/// Custom error types for the monitoring program
#[error_code]
pub enum MonitoringError {
    #[msg("Invalid maximum metrics configuration")]
    InvalidMaxMetrics,
    #[msg("Invalid maximum alerts configuration")]
    InvalidMaxAlerts,
    #[msg("Invalid maximum data points configuration")]
    InvalidMaxDataPoints,
    #[msg("Metric is currently disabled")]
    MetricDisabled,
    #[msg("Invalid timestamp")]
    InvalidTimestamp,
    #[msg("Value below configured minimum")]
    ValueBelowMinimum,
    #[msg("Value above configured maximum")]
    ValueAboveMaximum,
    #[msg("Rate of change exceeded configured maximum")]
    RateOfChangeExceeded,
}