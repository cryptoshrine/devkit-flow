import { startAnchor } from "solana-bankrun";
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey, Keypair, SystemProgram } from "@solana/web3.js";
import { expect } from "chai";
import { TestEngine } from "../../../target/types/test_engine";
import * as path from "path";

describe('test-engine', () => {
  const TEST_ENGINE_PROGRAM_ID = new PublicKey("DRtryNc2GJrhytBQK9STjphH5wyNopKuzne34kgdbLgx");
  
  let provider: anchor.AnchorProvider;
  let program: Program<TestEngine>;
  let authority: Keypair;
  let validator: Keypair;

  before(async () => {
    // Get the path to the program binary
    const programPath = path.join(__dirname, "../../fixtures/test_engine.so");
    
    // Start anchor with the program binary
    const context = await startAnchor(
      "",
      [{
        name: "test_engine",
        programId: TEST_ENGINE_PROGRAM_ID,
        binaryPath: programPath
      }],
      []
    );

    // Create new account keypairs
    authority = Keypair.generate();
    validator = Keypair.generate();

    // Add balance directly using banksClient
    await context.banksClient.addBalance(
      authority.publicKey,
      BigInt(10 * anchor.web3.LAMPORTS_PER_SOL)
    );
    await context.banksClient.addBalance(
      validator.publicKey,
      BigInt(10 * anchor.web3.LAMPORTS_PER_SOL)
    );

    // Set up provider with banks client
    provider = new anchor.AnchorProvider(
      context.banksClient as any,
      new anchor.Wallet(authority),
      { commitment: 'processed' }
    );
    
    // Initialize program with provider
    program = new Program<TestEngine>(
      require("../../../target/idl/test_engine.json"),
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

    const [testCasePda] = PublicKey.findProgramAddressSync(
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
