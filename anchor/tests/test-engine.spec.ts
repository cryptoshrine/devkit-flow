import { expect } from 'chai';
import * as anchor from '@coral-xyz/anchor';
import { Program } from '@coral-xyz/anchor';
import { Connection, Keypair, PublicKey, SystemProgram } from '@solana/web3.js';
import { TestEngine } from '../target/types/test_engine';

// Helper function for enum phase checking
const isPhase = (phase: any, expectedPhase: string) => {
    return phase && phase[expectedPhase] !== undefined;
};

describe('test-engine', () => {
    const provider = anchor.AnchorProvider.env();
    anchor.setProvider(provider);
    const program = anchor.workspace.TestEngine as Program<TestEngine>;

    let authority: Keypair;
    let validator: Keypair;
    let testCasePda: PublicKey;
    let executionStatePda: PublicKey;
    let resultStoragePda: PublicKey;

    const confirmTransaction = async (signature: string) => {
        const latestBlockhash = await provider.connection.getLatestBlockhash();
        await provider.connection.confirmTransaction({
            signature,
            ...latestBlockhash,
        });
    };

    before(async () => {
        try {
            // Initialize keypairs
            authority = Keypair.generate();
            validator = Keypair.generate();

            // Fund accounts
            const authorityAirdropSignature = await provider.connection.requestAirdrop(
                authority.publicKey,
                2 * anchor.web3.LAMPORTS_PER_SOL
            );
            await confirmTransaction(authorityAirdropSignature);

            const validatorAirdropSignature = await provider.connection.requestAirdrop(
                validator.publicKey,
                2 * anchor.web3.LAMPORTS_PER_SOL
            );
            await confirmTransaction(validatorAirdropSignature);

            // Derive PDAs
            [testCasePda] = PublicKey.findProgramAddressSync(
                [Buffer.from("test"), authority.publicKey.toBuffer()],
                program.programId
            );
            [executionStatePda] = PublicKey.findProgramAddressSync(
                [Buffer.from("execution"), testCasePda.toBuffer()],
                program.programId
            );
            [resultStoragePda] = PublicKey.findProgramAddressSync(
                [Buffer.from("results"), testCasePda.toBuffer()],
                program.programId
            );
        } catch (err) {
            console.error("Error in setup:", err);
            throw err;
        }
    });

    it('creates a test case', async () => {
        const testConfig = {
            name: "test-case-1",
            timeout: new anchor.BN(5000),
            requiredCoverage: 80,
            securityChecks: true,
        };

        await program.methods
            .createTest(testConfig)
            .accounts({
                authority: authority.publicKey,
                validator: validator.publicKey,
                testCase: testCasePda,
                systemProgram: SystemProgram.programId,
            }as any)
            .signers([authority])
            .rpc();

        const testCase = await program.account.testCase.fetch(testCasePda);
        // console.log('Created test case:', testCase);

        expect(testCase.config.name).to.equal(testConfig.name);
        expect(testCase.config.timeout.toNumber()).to.equal(testConfig.timeout.toNumber());
        expect(testCase.config.requiredCoverage).to.equal(testConfig.requiredCoverage);
        expect(testCase.config.securityChecks).to.equal(testConfig.securityChecks);
    });

    it('runs a test case', async () => {
        const runTestParams = {
            additionalSettings: null,
            coverageThreshold: 80,
        };

        const testCase = await program.account.testCase.fetchNullable(testCasePda);
        if (!testCase) {
            throw new Error("test_case account was not initialized properly.");
        }

        // console.log('Test case before run:', testCase);

        await program.methods
            .runTest(runTestParams)
            .accounts({
                authority: authority.publicKey,
                testCase: testCasePda,
                executionState: executionStatePda,
                systemProgram: SystemProgram.programId,
            }as any)
            .signers([authority])
            .rpc();

        const executionState = await program.account.testExecutionState.fetchNullable(executionStatePda);
        if (!executionState) {
            throw new Error("execution_state account was not initialized properly.");
        }

        // console.log('Execution state after run:', executionState);

        // Check phase using deep equality for enum comparison
        expect(executionState.currentPhase).to.deep.equal({ setup: {} });
        // Alternative check using helper function
        expect(isPhase(executionState.currentPhase, 'setup')).to.be.true;
        expect(executionState.totalInstructions).to.equal(0);
    });

    it('verifies test results', async () => {
        // Add delay to ensure some time passes
        await new Promise(resolve => setTimeout(resolve, 1000));

        const executionState = await program.account.testExecutionState.fetchNullable(executionStatePda);
        if (!executionState) {
            throw new Error("execution_state account was not initialized properly before verifyResults.");
        }

        // console.log('Execution state before verify:', executionState);

        await program.methods
            .verifyResults()
            .accounts({
                validator: validator.publicKey,
                testCase: testCasePda,
                executionState: executionStatePda,
                resultStorage: resultStoragePda,
                systemProgram: SystemProgram.programId,
            }as any)
            .signers([validator])
            .rpc();

        const testCase = await program.account.testCase.fetch(testCasePda);
        // console.log('Test case after verify:', testCase);

        expect(testCase.status).to.deep.equal({ completed: {} });

        const results = await program.account.testResults.fetch(resultStoragePda);
        // console.log('Test results:', results);

        // Corrected assertions for BN type
        expect(results.executionTime).to.exist;
        expect(results.executionTime instanceof anchor.BN).to.be.true;
        expect(results.executionTime.toNumber()).to.be.at.least(0);

        // Check gas usage
        expect(results.gasUsed instanceof anchor.BN).to.be.true;
        expect(results.gasUsed.toNumber()).to.be.at.least(0);
    });

    after(async () => {
        try {
            console.log("Running cleanup...");
            // Add any necessary cleanup logic here
            console.log("Cleanup completed successfully.");
        } catch (err) {
            console.error("Error during cleanup:", err);
        }
    });
});