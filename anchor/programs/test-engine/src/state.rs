use anchor_lang::prelude::*;

#[account]
pub struct TestCase {
    pub authority: Pubkey,
    pub validator: Pubkey,
    pub config: TestConfig,
    pub status: TestStatus,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug)]
pub struct TestConfig {
    pub name: String,
    pub timeout: u64,
    pub required_coverage: u8,
    pub security_checks: bool,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, PartialEq)]
pub enum TestStatus {
    Created,
    Running,
    Completed,
    Failed,
}

#[account]
pub struct TestExecutionState {
    pub test_case: Pubkey,
    pub current_phase: ExecutionPhase,
    pub total_instructions: u32,
    pub completed_instructions: u32,
    pub failed_instructions: u32,
    pub execution_time: u64,
    pub gas_used: u64,
    pub logs: Vec<String>,
    pub current_coverage: Option<CoverageReport>,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, PartialEq)]
pub enum ExecutionPhase {
    Setup,
    Running,
    Cleanup,
    Completed,
    Failed,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug)]
pub struct CoverageReport {
    pub line_coverage: u8,
    pub branch_coverage: u8,
    pub instruction_coverage: u8,
}

#[account]
pub struct TestResults {
    pub execution_time: u64,
    pub gas_used: u64,
    pub coverage: Option<CoverageReport>,
    pub verified_at: i64,
}