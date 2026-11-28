import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import { PrismaService } from '../src/prisma/prismaService.js';
import { SYNTHETIC_KEY_PREFIX, SYNTHETIC_USER_ID, seedSyntheticData, syntheticId } from '../src/seed/syntheticData.js';
import { TEST_CONFIG } from './support/testApp.js';

describe('syntheticId', () => {
  it('is a stable, valid version 4 UUID', () => {
    assert.equal(syntheticId('user'), syntheticId('user'));
    assert.notEqual(syntheticId('user'), syntheticId('device'));
    assert.match(syntheticId('user'), /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
  });
});

const databaseUrl = process.env['FLOWWAVE_TEST_DATABASE_URL'];

describe('synthetic seed against PostgreSQL', { skip: !databaseUrl }, () => {
  let prisma: PrismaService;

  before(async () => {
    prisma = new PrismaService({ ...TEST_CONFIG, databaseUrl: databaseUrl! });
    await prisma.user.deleteMany({ where: { id: SYNTHETIC_USER_ID } });
  });

  after(async () => {
    await prisma.user.deleteMany({ where: { id: SYNTHETIC_USER_ID } });
    await prisma.$disconnect();
  });

  it('creates marked records once and changes nothing when run again', async () => {
    const first = await seedSyntheticData(prisma);
    const countsAfterFirst = await countAll(prisma);
    const second = await seedSyntheticData(prisma);

    assert.ok(first.importsInserted > 0);
    assert.equal(second.importsInserted, 0);
    assert.equal(second.importsUnchanged, first.importsInserted);
    assert.deepEqual(await countAll(prisma), countsAfterFirst);

    const user = await prisma.user.findUniqueOrThrow({ where: { id: SYNTHETIC_USER_ID } });
    assert.equal(user.isSynthetic, true);
    const unmarkedSamples = await prisma.healthSample.count({
      where: { userId: SYNTHETIC_USER_ID, NOT: { idempotencyKey: { startsWith: SYNTHETIC_KEY_PREFIX } } },
    });
    assert.equal(unmarkedSamples, 0);
    const sources = await prisma.healthDataSource.findMany({ where: { userId: SYNTHETIC_USER_ID } });
    assert.ok(sources.every((source) => source.kind === 'synthetic'));
  });

  it('includes explicitly missing values instead of zeros', async () => {
    const missingSteps = await prisma.healthSample.count({
      where: { userId: SYNTHETIC_USER_ID, metric: 'steps', value: null, valueMissingReason: 'not_recorded' },
    });
    const zeroSteps = await prisma.healthSample.count({ where: { userId: SYNTHETIC_USER_ID, metric: 'steps', value: 0 } });
    assert.ok(missingSteps > 0);
    assert.equal(zeroSteps, 0);
  });
});

async function countAll(prisma: PrismaService): Promise<Record<string, number>> {
  const where = { userId: SYNTHETIC_USER_ID };
  return {
    healthSamples: await prisma.healthSample.count({ where }),
    sleepSessions: await prisma.sleepSession.count({ where }),
    activitySessions: await prisma.activitySession.count({ where }),
    deviceUsageBuckets: await prisma.deviceUsageBucket.count({ where }),
    selfCheckIns: await prisma.selfCheckIn.count({ where }),
    mealEvents: await prisma.mealEvent.count({ where }),
    caffeineEvents: await prisma.caffeineEvent.count({ where }),
    restEvents: await prisma.restEvent.count({ where }),
    focusSessions: await prisma.focusSession.count({ where }),
    dailyScores: await prisma.dailyScore.count({ where }),
    rhythmBuckets: await prisma.rhythmBucket.count({ where }),
    recommendations: await prisma.recommendation.count({ where }),
    syncCheckpoints: await prisma.syncCheckpoint.count({ where }),
    auditEvents: await prisma.auditEvent.count({ where }),
  };
}
