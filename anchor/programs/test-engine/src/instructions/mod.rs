use anchor_lang::prelude::*;
use crate::state::*;

#[derive(Accounts)]
#[instruction(config: TestConfig)]
pub struct CreateTest<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
    
    /// CHECK: This account is only used as a signing validator and is not written to
    pub validator: AccountInfo<'info>,  // Added safety check comment above
    
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
    
    /// CHECK: This account is used to track test execution state and is initialized in this instruction
    pub program_id: AccountInfo<'info>,

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
    
    /// CHECK: This account is only used for test execution verification
    pub program_id: AccountInfo<'info>,

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


#[derive(AnchorSerialize, AnchorDeserialize)]
pub struct RunTestParams {
    pub additional_settings: Option<String>,
}