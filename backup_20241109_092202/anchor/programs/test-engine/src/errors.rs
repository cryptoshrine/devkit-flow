// anchor/programs/test-engine/src/errors.rs
use anchor_lang::prelude::*;

#[error_code]
pub enum ErrorCode {
    #[msg("Invalid timeout value")]
    InvalidTimeout,
    
    #[msg("Invalid coverage requirement")]
    InvalidCoverageRequirement,
    
    #[msg("Test execution failed")]
    TestExecutionFailed,
    
    #[msg("Invalid test status for operation")]
    InvalidTestStatus,
    
    #[msg("Test execution incomplete")]
    TestExecutionIncomplete,
    
    #[msg("Insufficient test coverage")]
    InsufficientCoverage,

    #[msg("Coverage report missing")]
    MissingCoverageReport,

    #[msg("Invalid coverage data")]
    InvalidCoverageData,
}