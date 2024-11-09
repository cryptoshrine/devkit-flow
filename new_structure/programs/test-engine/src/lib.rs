use anchor_lang::prelude::*;
use crate::state::{TestCase, TestConfig, TestStatus};

declare_id!("DRtryNc2GJrhytBQK9STjphH5wyNopKuzne34kgdbLgx");

#[program]
pub mod test_engine {
    use super::*;
    
    pub fn create_test(ctx: Context<CreateTest>, config: TestConfig) -> Result<()> {
        let test_case = &mut ctx.accounts.test_case;
        test_case.authority = ctx.accounts.authority.key();
        test_case.validator = ctx.accounts.validator.key();
        test_case.config = config;
        test_case.status = TestStatus::Created;
        test_case.created_at = Clock::get()?.unix_timestamp;
        test_case.updated_at = Clock::get()?.unix_timestamp;
        Ok(())
    }

    pub fn run_test(ctx: Context<RunTest>, _params: RunTestParams) -> Result<()> {
        let test_case = &mut ctx.accounts.test_case;
        test_case.status = TestStatus::Running;
        test_case.updated_at = Clock::get()?.unix_timestamp;
        Ok(())
    }

    pub fn verify_results(ctx: Context<VerifyResults>) -> Result<()> {
        let test_case = &mut ctx.accounts.test_case;
        test_case.status = TestStatus::Completed;
        test_case.updated_at = Clock::get()?.unix_timestamp;
        Ok(())
    }
}

#[derive(Accounts)]
pub struct CreateTest<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + std::mem::size_of::<TestCase>()
    )]
    pub test_case: Account<'info, TestCase>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    /// CHECK: Validated in instruction
    pub validator: AccountInfo<'info>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct RunTest<'info> {
    #[account(
        mut,
        has_one = authority
    )]
    pub test_case: Account<'info, TestCase>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
}

#[derive(Accounts)]
pub struct VerifyResults<'info> {
    #[account(
        mut,
        has_one = validator
    )]
    pub test_case: Account<'info, TestCase>,
    
    #[account(mut)]
    pub validator: Signer<'info>,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug)]
pub struct RunTestParams {
    pub additional_settings: Option<String>,
}

pub mod state {
    use super::*;

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
}
