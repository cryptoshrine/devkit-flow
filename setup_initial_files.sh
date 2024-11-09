#!/bin/bash

# Initial File Setup Script for DevKit Flow
# Save this as setup_initial_files.sh

set -e

# Configuration
PROJECT_ROOT="${NEW_STRUCTURE_ROOT:-$(pwd)/new_structure}"
TEST_ENGINE_DIR="${PROJECT_ROOT}/programs/test-engine"

# Create test-engine program files
mkdir -p "${TEST_ENGINE_DIR}/src/"{state,instructions,errors}

# Create Cargo.toml
cat > "${TEST_ENGINE_DIR}/Cargo.toml" << 'EOF'
[package]
name = "test-engine"
version = "0.1.0"
description = "Created with Anchor"
edition = "2021"

[lib]
crate-type = ["cdylib", "lib"]
name = "test_engine"

[features]
no-entrypoint = []
no-idl = []
no-log-ix-name = []
cpi = ["no-entrypoint"]
default = []

[dependencies]
anchor-lang = { version = "0.30.1", features = ["init-if-needed"] }
EOF

# Create lib.rs
cat > "${TEST_ENGINE_DIR}/src/lib.rs" << 'EOF'
use anchor_lang::prelude::*;

declare_id!("DRtryNc2GJrhytBQK9STjphH5wyNopKuzne34kgdbLgx");

#[program]
pub mod test_engine {
    use super::*;
    
    pub fn create_test(ctx: Context<CreateTest>, config: TestConfig) -> Result<()> {
        msg!("Creating new test");
        Ok(())
    }

    pub fn run_test(ctx: Context<RunTest>, params: RunTestParams) -> Result<()> {
        msg!("Running test");
        Ok(())
    }

    pub fn verify_results(ctx: Context<VerifyResults>) -> Result<()> {
        msg!("Verifying results");
        Ok(())
    }
}

#[derive(Accounts)]
pub struct CreateTest<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct RunTest<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
}

#[derive(Accounts)]
pub struct VerifyResults<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug)]
pub struct TestConfig {
    pub name: String,
    pub timeout: u64,
    pub required_coverage: u8,
    pub security_checks: bool,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug)]
pub struct RunTestParams {
    pub additional_settings: Option<String>,
}
EOF

# Create state/mod.rs
cat > "${TEST_ENGINE_DIR}/src/state/mod.rs" << 'EOF'
use anchor_lang::prelude::*;

#[account]
pub struct TestCase {
    pub authority: Pubkey,
    pub validator: Pubkey,
    pub config: TestConfig,
    pub status: TestStatus,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug)]
pub struct TestConfig {
    pub name: String,
    pub timeout: u64,
    pub required_coverage: u8,
    pub security_checks: bool,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Debug, PartialEq)]
pub enum TestStatus {
    Created,
    Running,
    Completed,
    Failed,
}
EOF

# Create errors/mod.rs
cat > "${TEST_ENGINE_DIR}/src/errors/mod.rs" << 'EOF'
use anchor_lang::prelude::*;

#[error_code]
pub enum ErrorCode {
    #[msg("Invalid test configuration")]
    InvalidConfig,
    #[msg("Invalid timeout value")]
    InvalidTimeout,
    #[msg("Invalid coverage requirement")]
    InvalidCoverageRequirement,
    #[msg("Test execution incomplete")]
    TestExecutionIncomplete,
}
EOF

# Create test structure
mkdir -p "${PROJECT_ROOT}/tests/"{unit/test-engine,integration,utils}

# Create test files
cat > "${PROJECT_ROOT}/tests/unit/test-engine/test-engine.spec.ts" << 'EOF'
import { startAnchor } from "solana-bankrun";
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey, Keypair, SystemProgram } from "@solana/web3.js";
import { expect } from "chai";
import { TestEngine } from "../target/types/test_engine";

describe('test-engine', () => {
  const TEST_ENGINE_PROGRAM_ID = new PublicKey("DRtryNc2GJrhytBQK9STjphH5wyNopKuzne34kgdbLgx");
  
  let provider: anchor.AnchorProvider;
  let program: Program<TestEngine>;
  let authority: Keypair;
  let validator: Keypair;
  
  before(async () => {
    const context = await startAnchor(
      "",
      [{
        name: "test_engine",
        programId: TEST_ENGINE_PROGRAM_ID
      }],
      []
    );

    authority = anchor.web3.Keypair.generate();
    validator = anchor.web3.Keypair.generate();

    await context.banksClient.requestAirdrop(
      authority.publicKey,
      10 * anchor.web3.LAMPORTS_PER_SOL
    );

    program = new Program<TestEngine>(
      require("../target/idl/test_engine.json"),
      TEST_ENGINE_PROGRAM_ID,
      provider
    );
  });

  it("creates a test case", async () => {
    const testConfig = {
      name: "test-case-1",
      timeout: new anchor.BN(5000),
      requiredCoverage: 80,
      securityChecks: true
    };

    const [testCasePda] = anchor.web3.PublicKey.findProgramAddressSync(
      [
        Buffer.from("test"),
        authority.publicKey.toBuffer()
      ],
      program.programId
    );

    await program.methods
      .createTest(testConfig)
      .accounts({
        authority: authority.publicKey,
        testCase: testCasePda,
        systemProgram: SystemProgram.programId,
      })
      .signers([authority])
      .rpc();

    const testCase = await program.account.testCase.fetch(testCasePda);
    expect(testCase.config.name).to.equal(testConfig.name);
  });
});
EOF

# Create tsconfig.json
cat > "${PROJECT_ROOT}/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "types": ["mocha", "chai", "node"],
    "typeRoots": ["./node_modules/@types"],
    "lib": ["es2015"],
    "module": "commonjs",
    "target": "es6",
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "sourceMap": true,
    "outDir": "dist",
    "baseUrl": ".",
    "paths": {
      "*": ["node_modules/*"]
    }
  },
  "include": ["tests/**/*"],
  "exclude": ["node_modules"]
}
EOF

# Create package.json
cat > "${PROJECT_ROOT}/package.json" << 'EOF'
{
  "name": "test-engine",
  "version": "1.0.0",
  "main": "index.js",
  "directories": {
    "test": "tests"
  },
  "scripts": {
    "test": "ts-mocha -p ./tsconfig.json tests/**/*.ts",
    "test:local": "anchor test"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "description": "",
  "devDependencies": {
    "@coral-xyz/anchor": "^0.30.1",
    "@types/chai": "^5.0.1",
    "chai": "^5.1.2",
    "solana-bankrun": "^0.4.0",
    "ts-mocha": "^10.0.0",
    "typescript": "^4.9.5",
    "@types/mocha": "^10.0.1"
  },
  "dependencies": {
    "@solana/web3.js": "^1.78.0"
  }
}
EOF

echo "Initial files setup completed"
