import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prismaService.js';

export const DATABASE_PING_TIMEOUT_MS = 2000;

/** Checks that the database answers a trivial query within the timeout. */
@Injectable()
export class DatabaseHealth {
  constructor(private readonly prisma: PrismaService) {}

  async isUp(timeoutMs: number = DATABASE_PING_TIMEOUT_MS): Promise<boolean> {
    let timer: NodeJS.Timeout | undefined;
    const timeout = new Promise<false>((resolve) => {
      timer = setTimeout(() => resolve(false), timeoutMs);
    });
    const ping = this.prisma.$queryRaw`SELECT 1`.then(
      () => true,
      () => false,
    );
    try {
      return await Promise.race([ping, timeout]);
    } finally {
      clearTimeout(timer);
    }
  }
}
