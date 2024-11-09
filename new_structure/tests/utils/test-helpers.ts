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
