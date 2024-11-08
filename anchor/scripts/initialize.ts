import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey, Keypair, Connection } from "@solana/web3.js";
import { ChainWatch } from "../target/types/chain_watch";

async function main() {
    // Configure the client
    const connection = new Connection("http://localhost:8899", "confirmed");
    const wallet = new anchor.Wallet(Keypair.fromSecretKey(
        // Load your deployment keypair
        require("fs").readFileSync("deploy-keypair.json")
    ));
    
    const provider = new anchor.AnchorProvider(connection, wallet, {
        commitment: "confirmed",
    });
    
    const program = new anchor.Program<ChainWatch>(
        require("../target/idl/chain_watch.json"),
        new PublicKey("ChWAFLcKkE366wcF1cYaXbryzEKzRPmVR6RHYdwxvfYK"),
        provider
    );

    // Initialize monitoring
    const monitoringConfig = {
        samplingInterval: new anchor.BN(60),
        retentionPeriod: new anchor.BN(86400),
        maxMetrics: 100,
        maxAlerts: 50,
    };

    const [monitoringStatePda] = PublicKey.findProgramAddressSync(
        [Buffer.from("monitoring")],
        program.programId
    );

    try {
        const tx = await program.methods
            .initializeMonitoring(monitoringConfig)
            .accounts({
                monitoringState: monitoringStatePda,
                authority: wallet.publicKey,
                systemProgram: anchor.web3.SystemProgram.programId,
            })
            .rpc();

        console.log("Program initialized successfully!");
        console.log("Transaction signature:", tx);
    } catch (err) {
        console.error("Error initializing program:", err);
    }
}

main().catch(console.error);
