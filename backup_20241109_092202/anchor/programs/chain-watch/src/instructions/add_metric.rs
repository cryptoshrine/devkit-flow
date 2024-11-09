// src/instructions/add_metric.rs
use anchor_lang::prelude::*;
use crate::state::{MonitoringState, MetricAccount};
use crate::errors::MonitoringError;

#[derive(Accounts)]
#[instruction(name: String)]
pub struct AddMetric<'info> {
    #[account(mut)]
    pub monitoring_state: Account<'info, MonitoringState>,
    
    #[account(
        init,
        payer = authority,
        space = 8 + std::mem::size_of::<MetricAccount>(),
        seeds = [b"metric", name.as_bytes()],
        bump
    )]
    pub metric_account: Account<'info, MetricAccount>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

impl<'info> AddMetric<'info> {
    pub fn validate(&self, name: &str) -> Result<()> {
        require!(
            name.len() <= 32,
            MonitoringError::NameTooLong
        );
        Ok(())
    }
}