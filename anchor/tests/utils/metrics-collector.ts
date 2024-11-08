import { Connection, PublicKey, Transaction, SystemProgram } from '@solana/web3.js';
import * as anchor from '@coral-xyz/anchor';
import { Program } from '@coral-xyz/anchor';
import { ChainWatch } from '../../target/types/chain_watch';

interface MetricValue {
    timestamp: number;
    value: number;
}

export enum AlertCondition {
    GreaterThan = 'GreaterThan',
    LessThan = 'LessThan',
    Equals = 'Equals',
    NotEquals = 'NotEquals'
}

export interface AlertConfig {
    metricName: string;
    threshold: number;
    condition: AlertCondition;
    windowSize: number;
}

export class MetricsCollector {
    private metrics: Map<string, MetricValue[]> = new Map();
    private connection: Connection;
    private program: Program<ChainWatch>;
    private authority: anchor.web3.Keypair;
    
    constructor(
        connection: Connection,
        program: Program<ChainWatch>,
        authority: anchor.web3.Keypair
    ) {
        this.connection = connection;
        this.program = program;
        this.authority = authority;
    }

    async collectMetric(name: string, value: number) {
        const values = this.metrics.get(name) || [];
        const metricValue = {
            timestamp: Date.now(),
            value
        };
        values.push(metricValue);
        this.metrics.set(name, values);
        
        await this.persistMetric(name, value);
    }

    private async persistMetric(name: string, value: number) {
        try {
            // Find PDA for metric storage
            const [metricPda] = PublicKey.findProgramAddressSync(
                [
                    Buffer.from("metric"),
                    Buffer.from(name),
                    this.authority.publicKey.toBuffer()
                ],
                this.program.programId
            );

            // Record metric on-chain
            await this.program.methods
                .recordMetric(new anchor.BN(value))
                .accounts({
                    metricAccount: metricPda,
                    authority: this.authority.publicKey,
                    systemProgram: SystemProgram.programId,
                })
                .signers([this.authority])
                .rpc();

        } catch (error) {
            console.error(`Failed to persist metric ${name}:`, error);
            throw error;
        }
    }

    async getMetricHistory(name: string): Promise<MetricValue[]> {
        return this.metrics.get(name) || [];
    }

    async getLatestMetric(name: string): Promise<MetricValue | null> {
        const values = this.metrics.get(name) || [];
        return values.length > 0 ? values[values.length - 1] : null;
    }

    async clearMetrics(name?: string) {
        if (name) {
            this.metrics.delete(name);
        } else {
            this.metrics.clear();
        }
    }
}

export class AlertManager {
    private alertConfigs: AlertConfig[] = [];
    private metricsCollector: MetricsCollector;
    
    constructor(metricsCollector: MetricsCollector) {
        this.metricsCollector = metricsCollector;
    }

    addAlertConfig(config: AlertConfig) {
        this.alertConfigs.push(config);
    }

    removeAlertConfig(metricName: string) {
        this.alertConfigs = this.alertConfigs.filter(
            config => config.metricName !== metricName
        );
    }

    async checkAlerts(): Promise<Array<{ metricName: string, triggered: boolean, value: number }>> {
        const results = [];

        for (const config of this.alertConfigs) {
            const latestMetric = await this.metricsCollector.getLatestMetric(config.metricName);
            
            if (!latestMetric) {
                continue;
            }

            let triggered = false;
            switch (config.condition) {
                case AlertCondition.GreaterThan:
                    triggered = latestMetric.value > config.threshold;
                    break;
                case AlertCondition.LessThan:
                    triggered = latestMetric.value < config.threshold;
                    break;
                case AlertCondition.Equals:
                    triggered = latestMetric.value === config.threshold;
                    break;
                case AlertCondition.NotEquals:
                    triggered = latestMetric.value !== config.threshold;
                    break;
            }

            results.push({
                metricName: config.metricName,
                triggered,
                value: latestMetric.value
            });
        }

        return results;
    }

    async getMetricTrend(metricName: string, windowSize: number): Promise<{
        average: number;
        min: number;
        max: number;
    }> {
        const history = await this.metricsCollector.getMetricHistory(metricName);
        const recentValues = history.slice(-windowSize);

        if (recentValues.length === 0) {
            return { average: 0, min: 0, max: 0 };
        }

        const values = recentValues.map(v => v.value);
        return {
            average: values.reduce((a, b) => a + b, 0) / values.length,
            min: Math.min(...values),
            max: Math.max(...values)
        };
    }

    getAlertConfigs(): AlertConfig[] {
        return [...this.alertConfigs];
    }

    clearAlertConfigs() {
        this.alertConfigs = [];
    }
}