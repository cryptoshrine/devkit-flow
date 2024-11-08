// src/lib.rs
use anchor_lang::prelude::*;

pub mod state;
pub mod errors;
pub mod instructions;
pub mod constants;

use instructions::*;
use state::*;
use errors::MonitoringError;

declare_id!("8wq6TVhdTeWiUWXib3vxJguDE9Nm3dmV99YxFCWL3WEe");

#[program]
pub mod chain_watch {
    use super::*;

    pub fn initialize_monitoring(
        ctx: Context<InitializeMonitoring>,
        config: MonitoringConfig,
    ) -> Result<()> {
        let monitoring_state = &mut ctx.accounts.monitoring_state;
        monitoring_state.authority = ctx.accounts.authority.key();
        monitoring_state.config = config;
        monitoring_state.metrics = Vec::new();
        monitoring_state.alerts = Vec::new();
        Ok(())
    }

    pub fn add_metric(
        ctx: Context<AddMetric>,
        name: String,
        params: MetricParams,
    ) -> Result<()> {
        ctx.accounts.validate(&name)?;
        
        let metric_account = &mut ctx.accounts.metric_account;
        metric_account.authority = ctx.accounts.authority.key();
        metric_account.name = name;
        metric_account.params = params;
        metric_account.enabled = true;
        metric_account.last_updated = Clock::get()?.unix_timestamp;
        metric_account.data_points = Vec::new();
        
        ctx.accounts.monitoring_state.metrics.push(metric_account.key());
        Ok(())
    }

    pub fn configure_alert(
        ctx: Context<ConfigureAlert>,
        params: AlertConfigParams,
    ) -> Result<()> {
        let alert_config = &mut ctx.accounts.alert_config;
        alert_config.authority = ctx.accounts.authority.key();
        alert_config.metric = ctx.accounts.metric_account.key();
        alert_config.params = params;
        alert_config.enabled = true;
        alert_config.last_triggered = 0;
        
        ctx.accounts.monitoring_state.alerts.push(alert_config.key());
        Ok(())
    }
}