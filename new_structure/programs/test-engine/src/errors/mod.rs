use anchor_lang::prelude::*;

#[error_code]
pub enum ErrorCode {
    #[msg("Invalid test configuration")]
    InvalidConfig,
    #[msg("Invalid timeout value")]
    InvalidTimeout,
    #[msg("Invalid coverage requirement")]
    InvalidCoverageRequirement,
    #[msg("Test execution incomplete")]
    TestExecutionIncomplete,
}
