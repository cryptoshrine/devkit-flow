use anchor_lang::prelude::*;

declare_id!("8FomnyS1eniLttdgeTcEjPAqJoMzf5jYVvdUyH8MUND");

#[program]
pub mod deploy_guard {
    use super::*;
    
    // Your program functions will go here
    pub fn initialize(_ctx: Context<Initialize>) -> Result<()> {
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}