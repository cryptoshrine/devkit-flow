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
