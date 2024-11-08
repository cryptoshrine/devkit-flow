// src/instructions/initialize.rs
use anchor_lang::prelude::*;
use crate::state::{MonitoringState, MonitoringConfig};

#[derive(Accounts)]
pub struct InitializeMonitoring<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + std::mem::size_of::<MonitoringState>(),
        seeds = [b"monitoring"],
        bump
    )]
    pub monitoring_state: Account<'info, MonitoringState>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}