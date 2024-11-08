import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey, Connection } from "@solana/web3.js";
import { ChainWatch } from "../target/types/chain_watch";

async function verify() {
    const connection = new Connection(process.env.SOLANA_RPC_URL || "http://localhost:8899");
    
    // Load program
    const programId = new PublicKey("ChWAFLcKkE366wcF1cYaXbryzEKzRPmVR6RHYdwxvfYK");
    
    // Verify program deployment
    const programInfo = await connection.getAccountInfo(programId);
    if (!programInfo) {
        throw new Error("Program not found!");
    }
    
    console.log("Program successfully deployed!");
    console.log("Program executable:", programInfo.executable);
    console.log("Program owner:", programInfo.owner.toBase58());
    
    // Verify monitoring state account
    const [monitoringStatePda] = PublicKey.findProgramAddressSync(
        [Buffer.from("monitoring")],
        programId
    );
    
    const monitoringStateInfo = await connection.getAccountInfo(monitoringStatePda);
    console.log("Monitoring state initialized:", !!monitoringStateInfo);
}

verify().catch(console.error);
