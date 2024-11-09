#!/bin/bash

# Test Files Setup Script - Save as setup_test_files.sh

# Set up paths
PROJECT_ROOT="${NEW_STRUCTURE_ROOT:-$(pwd)/new_structure}"
TEST_DIR="${PROJECT_ROOT}/tests"

# Create test directories if they don't exist
mkdir -p "${TEST_DIR}/"{unit/test-engine,unit/deploy-guard,integration,utils}

# Create test-engine test file
cat > "${TEST_DIR}/unit/test-engine/test-engine.test.ts" << 'EOF'
import { startAnchor, BankrunProvider } from "solana-bankrun";
import * as anchor from "@coral-xyz/anchor";
import { Connection, PublicKey, Keypair, SystemProgram } from "@solana/web3.js";
import { expect } from "chai";
import { TestEngine } from "../target/types/test_engine";

describe('test-engine', () => {
  const TEST_ENGINE_PROGRAM_ID = new PublicKey("DRtryNc2GJrhytBQK9STjphH5wyNopKuzne34kgdbLgx");
  
  let provider: anchor.AnchorProvider;
  let program: Program<TestEngine>;
  let authority: Keypair;
  let validator: Keypair;
  let connection: Connection;
  
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

    connection = {
      ...context.banksClient,
      commitment: 'processed'
    } as Connection;

    provider = new anchor.AnchorProvider(
      connection,
      new anchor.Wallet(authority),
      { commitment: 'processed' }
    );
    anchor.setProvider(provider);

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

# Create deploy-guard test file
cat > "${TEST_DIR}/unit/deploy-guard/deploy-guard.test.ts" << 'EOF'
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey, Keypair, SystemProgram } from "@solana/web3.js";
import { expect } from "chai";

describe('deploy-guard', () => {
  // Placeholder test until deploy-guard implementation is ready
  it("should be implemented", () => {
    expect(true).to.be.true;
  });
});
EOF

# Create integration test file
cat > "${TEST_DIR}/integration/integration-tests.ts" << 'EOF'
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey } from "@solana/web3.js";
import { expect } from "chai";

describe('Integration Tests', () => {
  it("test-engine and deploy-guard integration", async () => {
    // Integration test implementation will be added
    expect(true).to.be.true;
  });
});
EOF

# Create test helpers file
cat > "${TEST_DIR}/utils/test-helpers.ts" << 'EOF'
import { web3, BN } from '@coral-xyz/anchor';
import { PublicKey, Keypair } from '@solana/web3.js';

export interface TestConfigInput {
  name: string;
  timeout: number;
  required_coverage: number;
  security_checks: boolean;
}

export const createTestConfig = (input: TestConfigInput) => {
  return {
    name: input.name,
    timeout: new BN(input.timeout),
    required_coverage: input.required_coverage,
    security_checks: input.security_checks
  };
};

export const findTestPdas = (
  testName: string,
  authority: PublicKey,
  programId: PublicKey
) => {
  const [testCasePda] = PublicKey.findProgramAddressSync(
    [
      Buffer.from("test"),
      authority.toBuffer()
    ],
    programId
  );

  const [executionPda] = PublicKey.findProgramAddressSync(
    [
      Buffer.from("execution"),
      testCasePda.toBuffer()
    ],
    programId
  );

  return {
    testCasePda,
    executionPda
  };
};

export const sleep = (ms: number): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms));
};
EOF

echo "Test files setup completed"
