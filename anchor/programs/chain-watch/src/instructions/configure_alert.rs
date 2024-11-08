// src/instructions/configure_alert.rs
use anchor_lang::prelude::*;
use crate::state::{AlertConfig, MonitoringState, MetricAccount};

#[derive(Accounts)]
pub struct ConfigureAlert<'info> {
    #[account(mut)]
    pub monitoring_state: Account<'info, MonitoringState>,

    #[account(
        init,
        payer = authority,
        space = 8 + std::mem::size_of::<AlertConfig>(),
        seeds = [b"alert", metric_account.key().as_ref()],
        bump
    )]
    pub alert_config: Account<'info, AlertConfig>,

    pub metric_account: Account<'info, MetricAccount>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}