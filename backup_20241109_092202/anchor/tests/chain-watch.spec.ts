import { startAnchor } from "solana-bankrun";
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey, Keypair, SystemProgram } from "@solana/web3.js";
import { expect } from "chai";
import { ChainWatch } from "../target/types/chain_watch";
import { MetricsCollector, AlertManager, AlertCondition } from './utils/metrics-collector';

describe('chain-watch', () => {
    const CHAIN_WATCH_PROGRAM_ID = new PublicKey("8wq6TVhdTeWiUWXib3vxJguDE9Nm3dmV99YxFCWL3WEe");
    
    let provider: anchor.AnchorProvider;
    let program: Program<ChainWatch>;
    let authority: Keypair;
    let metricsCollector: MetricsCollector;
    let alertManager: AlertManager;
    
    before(async () => {
        const context = await startAnchor(
            "",
            [{
                name: "chain_watch",
                programId: CHAIN_WATCH_PROGRAM_ID
            }],
            []
        );

        authority = anchor.web3.Keypair.generate();
        
        await context.banksClient.requestAirdrop(
            authority.publicKey,
            10 * anchor.web3.LAMPORTS_PER_SOL
        );

        provider = new anchor.AnchorProvider(
            context.banksClient as any,
            new anchor.Wallet(authority),
            { commitment: 'processed' }
        );
        
        program = new anchor.Program(
            require("../target/idl/chain_watch.json"),
            CHAIN_WATCH_PROGRAM_ID,
            provider
        );

        // Initialize metrics collector and alert manager
        metricsCollector = new MetricsCollector(
            provider.connection,
            program,
            authority
        );
        alertManager = new AlertManager(metricsCollector);
    });

    it("initializes monitoring", async () => {
        const monitoringConfig = {
            samplingInterval: new anchor.BN(60), // 1 minute
            retentionPeriod: new anchor.BN(86400), // 1 day
            maxMetrics: 100,
            maxAlerts: 50,
        };

        const [monitoringStatePda] = PublicKey.findProgramAddressSync(
            [Buffer.from("monitoring")],
            program.programId
        );

        await program.methods
            .initializeMonitoring(monitoringConfig)
            .accounts({
                monitoringState: monitoringStatePda,
                authority: authority.publicKey,
                systemProgram: SystemProgram.programId,
            })
            .signers([authority])
            .rpc();

        const state = await program.account.monitoringState.fetch(monitoringStatePda);
        expect(state.config.samplingInterval.toNumber()).to.equal(60);
        expect(state.metrics).to.have.length(0);
        expect(state.alerts).to.have.length(0);
    });

    it("collects and persists metrics", async () => {
        const metricName = "cpu_usage";
        const metricValue = 75;

        await metricsCollector.collectMetric(metricName, metricValue);
        
        const latestMetric = await metricsCollector.getLatestMetric(metricName);
        expect(latestMetric).to.not.be.null;
        expect(latestMetric!.value).to.equal(metricValue);
    });

    it("configures and checks alerts", async () => {
        const metricName = "memory_usage";
        const threshold = 90;

        // Configure alert
        alertManager.addAlertConfig({
            metricName,
            threshold,
            condition: AlertCondition.GreaterThan,
            windowSize: 5
        });

        // Test below threshold
        await metricsCollector.collectMetric(metricName, 85);
        let alerts = await alertManager.checkAlerts();
        expect(alerts[0].triggered).to.be.false;

        // Test above threshold
        await metricsCollector.collectMetric(metricName, 95);
        alerts = await alertManager.checkAlerts();
        expect(alerts[0].triggered).to.be.true;
    });

    it("calculates metric trends", async () => {
        const metricName = "network_latency";
        const values = [100, 150, 200, 175, 125];

        // Collect multiple metrics
        for (const value of values) {
            await metricsCollector.collectMetric(metricName, value);
        }

        const trend = await alertManager.getMetricTrend(metricName, 5);
        
        expect(trend.average).to.equal(150);
        expect(trend.min).to.equal(100);
        expect(trend.max).to.equal(200);
    });

    it("handles multiple alerts", async () => {
        // Configure multiple alerts
        alertManager.clearAlertConfigs();
        
        const alerts = [
            {
                metricName: "cpu_usage",
                threshold: 90,
                condition: AlertCondition.GreaterThan,
                windowSize: 5
            },
            {
                metricName: "memory_usage",
                threshold: 80,
                condition: AlertCondition.GreaterThan,
                windowSize: 5
            },
            {
                metricName: "disk_usage",
                threshold: 95,
                condition: AlertCondition.GreaterThan,
                windowSize: 5
            }
        ];

        alerts.forEach(alert => alertManager.addAlertConfig(alert));

        // Collect metrics that should trigger some alerts
        await metricsCollector.collectMetric("cpu_usage", 95);
        await metricsCollector.collectMetric("memory_usage", 75);
        await metricsCollector.collectMetric("disk_usage", 98);

        const results = await alertManager.checkAlerts();
        
        expect(results).to.have.length(3);
        expect(results.filter(r => r.triggered)).to.have.length(2); // CPU and Disk should be triggered
    });

    it("maintains metric history", async () => {
        const metricName = "requests_per_second";
        await metricsCollector.clearMetrics(metricName);

        const values = [100, 200, 300, 400, 500];
        for (const value of values) {
            await metricsCollector.collectMetric(metricName, value);
        }

        const history = await metricsCollector.getMetricHistory(metricName);
        expect(history).to.have.length(values.length);
        expect(history.map(h => h.value)).to.deep.equal(values);
    });

    after(async () => {
        // Cleanup
        await metricsCollector.clearMetrics();
        alertManager.clearAlertConfigs();
    });
});