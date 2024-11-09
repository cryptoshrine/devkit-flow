// Here we export some useful types and functions for interacting with the Anchor program.
import { AnchorProvider, Program } from '@coral-xyz/anchor'
import { Cluster, PublicKey } from '@solana/web3.js'
import DevkitflowIDL from '../target/idl/devkitflow.json'
import type { Devkitflow } from '../target/types/devkitflow'

// Re-export the generated IDL and type
export { Devkitflow, DevkitflowIDL }

// The programId is imported from the program IDL.
export const DEVKITFLOW_PROGRAM_ID = new PublicKey(DevkitflowIDL.address)

// This is a helper function to get the Devkitflow Anchor program.
export function getDevkitflowProgram(provider: AnchorProvider) {
  return new Program(DevkitflowIDL as Devkitflow, provider)
}

// This is a helper function to get the program ID for the Devkitflow program depending on the cluster.
export function getDevkitflowProgramId(cluster: Cluster) {
  switch (cluster) {
    case 'devnet':
    case 'testnet':
      // This is the program ID for the Devkitflow program on devnet and testnet.
      return new PublicKey('CounNZdmsQmWh7uVngV9FXW2dZ6zAgbJyYsvBpqbykg')
    case 'mainnet-beta':
    default:
      return DEVKITFLOW_PROGRAM_ID
  }
}
