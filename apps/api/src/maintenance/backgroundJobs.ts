import { Inject, Injectable, Logger, type OnApplicationBootstrap, type OnApplicationShutdown } from '@nestjs/common';
import { DataExportService } from '../account/dataExportService.js';
import { APP_CONFIG, type AppConfig } from '../config/appConfig.js';
import { RetentionService } from './retentionService.js';

export const EXPORT_POLL_INTERVAL_MS = 15_000;
export const RETENTION_INTERVAL_MS = 3_600_000;

/**
 * Runs exports and retention inside the API process (decision 0014). Jobs are
 * claimed atomically, so moving them to a separate worker needs no change here.
 */
@Injectable()
export class BackgroundJobs implements OnApplicationBootstrap, OnApplicationShutdown {
  private readonly logger = new Logger(BackgroundJobs.name);
  private readonly timers: NodeJS.Timeout[] = [];
  private readonly running = new Set<string>();

  constructor(
    private readonly exports: DataExportService,
    private readonly retention: RetentionService,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  onApplicationBootstrap(): void {
    if (!this.config.backgroundJobsEnabled) return;
    this.schedule('exports', EXPORT_POLL_INTERVAL_MS, () => this.exports.processPending());
    this.schedule('retention', RETENTION_INTERVAL_MS, () => this.retention.run());
  }

  onApplicationShutdown(): void {
    for (const timer of this.timers) clearInterval(timer);
    this.timers.length = 0;
  }

  private schedule(name: string, intervalMs: number, job: () => Promise<unknown>): void {
    const tick = async () => {
      if (this.running.has(name)) return;
      this.running.add(name);
      try {
        const result = await job();
        this.logger.debug({ job: name, result }, 'Background job finished');
      } catch (error) {
        this.logger.error({ job: name, errorName: error instanceof Error ? error.name : 'unknown' }, 'Background job failed');
      } finally {
        this.running.delete(name);
      }
    };
    const timer = setInterval(() => void tick(), intervalMs);
    timer.unref();
    this.timers.push(timer);
    setImmediate(() => void tick());
  }
}
