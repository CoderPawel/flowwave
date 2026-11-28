import { Inject, Injectable } from '@nestjs/common';
import { Prisma } from '../../generated/prisma/client.js';
import { addDays, addSeconds, CLOCK, type Clock } from '../common/clock.js';
import { PrismaService } from '../prisma/prismaService.js';

/** Retention periods from decision 0014. */
export const RETENTION = {
  endedSessionDays: 30,
  exportJobDays: 30,
  tombstoneDays: 90,
  /** A job still running after this was interrupted (for example by a restart). */
  runningExportSeconds: 3600,
} as const;

export interface RetentionReport {
  readonly sessionsDeleted: number;
  readonly exportsInterrupted: number;
  readonly exportsExpired: number;
  readonly exportJobsDeleted: number;
  readonly tombstonesDeleted: number;
}

@Injectable()
export class RetentionService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  async run(): Promise<RetentionReport> {
    const now = this.clock.now();
    const sessionCutoff = addDays(now, -RETENTION.endedSessionDays);
    const tombstoneCutoff = addDays(now, -RETENTION.tombstoneDays);

    const sessions = await this.prisma.authSession.deleteMany({
      where: { OR: [{ revokedAtUtc: { lt: sessionCutoff } }, { expiresAtUtc: { lt: sessionCutoff } }] },
    });
    const interrupted = await this.prisma.dataExportJob.updateMany({
      where: { status: 'running', startedAtUtc: { lt: addSeconds(now, -RETENTION.runningExportSeconds) } },
      data: { status: 'failed', failureCode: 'export_interrupted', completedAtUtc: now },
    });
    const expired = await this.prisma.dataExportJob.updateMany({
      where: { status: 'completed', expiresAtUtc: { lte: now } },
      data: { status: 'expired', result: Prisma.DbNull },
    });
    const jobs = await this.prisma.dataExportJob.deleteMany({
      where: { requestedAtUtc: { lt: addDays(now, -RETENTION.exportJobDays) }, status: { notIn: ['pending', 'running'] } },
    });

    const tombstone = { deletedAtUtc: { lt: tombstoneCutoff } };
    const tombstoneCounts = await this.prisma.$transaction([
      this.prisma.healthSample.deleteMany({ where: tombstone }),
      this.prisma.sleepSession.deleteMany({ where: tombstone }),
      this.prisma.activitySession.deleteMany({ where: tombstone }),
      this.prisma.selfCheckIn.deleteMany({ where: tombstone }),
      this.prisma.mealEvent.deleteMany({ where: tombstone }),
      this.prisma.caffeineEvent.deleteMany({ where: tombstone }),
      this.prisma.restEvent.deleteMany({ where: tombstone }),
      this.prisma.focusSession.deleteMany({ where: tombstone }),
    ]);

    return {
      sessionsDeleted: sessions.count,
      exportsInterrupted: interrupted.count,
      exportsExpired: expired.count,
      exportJobsDeleted: jobs.count,
      tombstonesDeleted: tombstoneCounts.reduce((sum, result) => sum + result.count, 0),
    };
  }
}
