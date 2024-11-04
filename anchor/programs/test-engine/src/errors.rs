use anchor_lang::prelude::*;

#[error_code]
pub enum ErrorCode {
    #[msg("Invalid timeout value")]
    InvalidTimeout,
    
    #[msg("Invalid coverage requirement")]
    InvalidCoverageRequirement,
    
    #[msg("Invalid test status for operation")]
    InvalidTestStatus,
    
    #[msg("Test execution incomplete")]
    TestExecutionIncomplete,
    
    #[msg("Insufficient test coverage")]
    InsufficientCoverage,
}