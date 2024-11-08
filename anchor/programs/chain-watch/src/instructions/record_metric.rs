// programs/chain-watch/src/instructions/record_metric.rs
use anchor_lang::prelude::*;
use crate::state::MetricAccount;
use crate::errors::MonitoringError;  // Updated error enum name

#[derive(Accounts)]
pub struct RecordMetric<'info> {
    #[account(mut)]
    pub metric_account: Account<'info, MetricAccount>,
    pub authority: Signer<'info>,
}