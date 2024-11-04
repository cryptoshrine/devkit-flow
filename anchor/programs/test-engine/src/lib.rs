use anchor_lang::prelude::*;

// Declare modules
mod state;
mod errors;
mod instructions;

// Import all needed types
use state::{
    TestCase, 
    TestConfig, 
    TestStatus, 
    TestExecutionState, 
    ExecutionPhase,
    TestResults,
    CoverageReport,
};
use errors::ErrorCode;
use instructions::RunTestParams;

declare_id!("EzCvHeuefRbpjA6gXAChdQiXp6qLVsAF3jWby3wCgTiz");

// Define the account structures in lib.rs
#[derive(Accounts)]
pub struct CreateTest<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
    /// CHECK: This account is only used as a signing validator
    pub validator: AccountInfo<'info>,
    #[account(
        init,
        payer = authority,
        space = 8 + std::mem::size_of::<TestCase>(),
        seeds = [b"test", authority.key().as_ref()],
        bump
    )]
    pub test_case: Account<'info, TestCase>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct RunTest<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
    #[account(
        mut,
        constraint = test_case.authority == authority.key()
    )]
    pub test_case: Account<'info, TestCase>,
    #[account(
        init,
        payer = authority,
        space = 8 + std::mem::size_of::<TestExecutionState>(),
        seeds = [b"execution", test_case.key().as_ref()],
        bump
    )]
    pub execution_state: Account<'info, TestExecutionState>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct VerifyResults<'info> {
    #[account(mut)]
    pub validator: Signer<'info>,
    #[account(
        mut,
        constraint = test_case.validator == validator.key()
    )]
    pub test_case: Account<'info, TestCase>,
    #[account(
        mut,
        seeds = [b"execution", test_case.key().as_ref()],
        bump
    )]
    pub execution_state: Account<'info, TestExecutionState>,
    #[account(
        init_if_needed,
        payer = validator,
        space = 8 + std::mem::size_of::<TestResults>(),
        seeds = [b"results", test_case.key().as_ref()],
        bump
    )]
    pub result_storage: Account<'info, TestResults>,
    pub system_program: Program<'info, System>,
}

#[program]
mod test_engine {
    use super::*;

    pub fn create_test(ctx: Context<CreateTest>, config: TestConfig) -> Result<()> {
        require!(
            config.timeout >= 1000 && config.timeout <= 300000,
            ErrorCode::InvalidTimeout
        );
        require!(
            config.required_coverage > 0 && config.required_coverage <= 100,
            ErrorCode::InvalidCoverageRequirement
        );

        let test_case = &mut ctx.accounts.test_case;
        
        test_case.authority = ctx.accounts.authority.key();
        test_case.validator = ctx.accounts.validator.key();
        test_case.config = config;
        test_case.status = TestStatus::Created;
        test_case.created_at = Clock::get()?.unix_timestamp;
        test_case.updated_at = Clock::get()?.unix_timestamp;

        msg!("Test case created successfully");
        Ok(())
    }

    pub fn run_test(ctx: Context<RunTest>, _params: RunTestParams) -> Result<()> {
        let test_case = &mut ctx.accounts.test_case;
        let execution = &mut ctx.accounts.execution_state;

        require!(
            test_case.status == TestStatus::Created,
            ErrorCode::InvalidTestStatus
        );

        execution.test_case = test_case.key();
        execution.current_phase = ExecutionPhase::Setup;
        execution.total_instructions = 0;
        execution.completed_instructions = 0;
        execution.failed_instructions = 0;
        execution.logs = Vec::new();

        test_case.status = TestStatus::Running;
        test_case.updated_at = Clock::get()?.unix_timestamp;

        msg!("Test execution started");
        Ok(())
    }

    pub fn verify_results(ctx: Context<VerifyResults>) -> Result<()> {
        let test_case = &mut ctx.accounts.test_case;
        let execution = &ctx.accounts.execution_state;
        let results = &mut ctx.accounts.result_storage;

        require!(
            test_case.status == TestStatus::Running,
            ErrorCode::InvalidTestStatus
        );

        if let Some(coverage) = &execution.current_coverage {
            require!(
                coverage.line_coverage >= test_case.config.required_coverage,
                ErrorCode::InsufficientCoverage
            );
        }

        results.execution_time = execution.execution_time;
        results.gas_used = execution.gas_used;
        results.coverage = execution.current_coverage.clone();
        results.verified_at = Clock::get()?.unix_timestamp;

        test_case.status = TestStatus::Completed;
        test_case.updated_at = Clock::get()?.unix_timestamp;

        msg!("Test results verified successfully");
        Ok(())
    }
}