// src/errors.rs
use anchor_lang::prelude::*;

#[error_code]
pub enum MonitoringError {
    #[msg("Name exceeds maximum length")]
    NameTooLong,
    #[msg("Invalid monitoring configuration")]
    InvalidConfig,
    #[msg("Invalid metric parameters")]
    InvalidMetricParams,
    #[msg("Invalid alert configuration")]
    InvalidAlertConfig,
}