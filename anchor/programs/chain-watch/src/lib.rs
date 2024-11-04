use anchor_lang::prelude::*;

declare_id!("tYvJgXVRNagbqjq6LuackN27qDxUDB2pRvN5GH6mZvM");

#[program]
pub mod chain_watch {
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