import { Controller, Get, HttpStatus, Res } from '@nestjs/common';
import { ApiOkResponse, ApiOperation, ApiProperty, ApiServiceUnavailableResponse, ApiTags } from '@nestjs/swagger';
import { Public } from '../auth/authGuard.js';
import { RateLimit } from '../rateLimit/rateLimitGuard.js';
import { DatabaseHealth } from './databaseHealth.js';

export class LivenessResponse {
  @ApiProperty({ enum: ['ok'], example: 'ok' })
  readonly status!: 'ok';
}

export class ReadinessChecks {
  @ApiProperty({ enum: ['up', 'down'], example: 'up' })
  readonly database!: 'up' | 'down';
}

export class ReadinessResponse {
  @ApiProperty({ enum: ['ok', 'unavailable'], example: 'ok' })
  readonly status!: 'ok' | 'unavailable';

  @ApiProperty({ type: ReadinessChecks })
  readonly checks!: ReadinessChecks;
}

interface StatusSetter {
  status(code: number): unknown;
}

@ApiTags('health')
@Public()
@RateLimit(null)
@Controller('health')
export class HealthController {
  constructor(private readonly database: DatabaseHealth) {}

  @Get()
  @ApiOperation({ summary: 'Liveness: the process is running. Does not touch the database.' })
  @ApiOkResponse({ type: LivenessResponse })
  live(): LivenessResponse {
    return { status: 'ok' };
  }

  @Get('ready')
  @ApiOperation({ summary: 'Readiness: the API can reach the database.' })
  @ApiOkResponse({ type: ReadinessResponse })
  @ApiServiceUnavailableResponse({ type: ReadinessResponse })
  async ready(@Res({ passthrough: true }) response: StatusSetter): Promise<ReadinessResponse> {
    const databaseUp = await this.database.isUp();
    if (!databaseUp) {
      response.status(HttpStatus.SERVICE_UNAVAILABLE);
      return { status: 'unavailable', checks: { database: 'down' } };
    }
    return { status: 'ok', checks: { database: 'up' } };
  }
}
