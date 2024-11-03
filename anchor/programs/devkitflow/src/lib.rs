#![allow(clippy::result_large_err)]

use anchor_lang::prelude::*;

declare_id!("AsjZ3kWAUSQRNt2pZVeJkywhZ6gpLpHZmJjduPmKZDZZ");

#[program]
pub mod devkitflow {
    use super::*;

  pub fn close(_ctx: Context<CloseDevkitflow>) -> Result<()> {
    Ok(())
  }

  pub fn decrement(ctx: Context<Update>) -> Result<()> {
    ctx.accounts.devkitflow.count = ctx.accounts.devkitflow.count.checked_sub(1).unwrap();
    Ok(())
  }

  pub fn increment(ctx: Context<Update>) -> Result<()> {
    ctx.accounts.devkitflow.count = ctx.accounts.devkitflow.count.checked_add(1).unwrap();
    Ok(())
  }

  pub fn initialize(_ctx: Context<InitializeDevkitflow>) -> Result<()> {
    Ok(())
  }

  pub fn set(ctx: Context<Update>, value: u8) -> Result<()> {
    ctx.accounts.devkitflow.count = value.clone();
    Ok(())
  }
}

#[derive(Accounts)]
pub struct InitializeDevkitflow<'info> {
  #[account(mut)]
  pub payer: Signer<'info>,

  #[account(
  init,
  space = 8 + Devkitflow::INIT_SPACE,
  payer = payer
  )]
  pub devkitflow: Account<'info, Devkitflow>,
  pub system_program: Program<'info, System>,
}
#[derive(Accounts)]
pub struct CloseDevkitflow<'info> {
  #[account(mut)]
  pub payer: Signer<'info>,

  #[account(
  mut,
  close = payer, // close account and return lamports to payer
  )]
  pub devkitflow: Account<'info, Devkitflow>,
}

#[derive(Accounts)]
pub struct Update<'info> {
  #[account(mut)]
  pub devkitflow: Account<'info, Devkitflow>,
}

#[account]
#[derive(InitSpace)]
pub struct Devkitflow {
  count: u8,
}
