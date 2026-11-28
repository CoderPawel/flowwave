import { Body, Controller, Get, HttpStatus, Post, Res } from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { ConsentDecision } from '@flowwave/core';
import { CurrentAuth } from '../auth/authGuard.js';
import type { AuthContext } from '../auth/authService.js';
import {
  ConsentDecisionResponse,
  ConsentStatusResponse,
  RecordConsentRequest,
  RecordConsentResponse,
} from './consentDtos.js';
import { ConsentService } from './consentService.js';

interface StatusSetter {
  status(code: number): unknown;
}

function decisionResponse(decision: ConsentDecision): ConsentDecisionResponse {
  return { ...decision, scopes: [...decision.scopes] };
}

@ApiTags('consents')
@ApiBearerAuth()
@Controller('consents')
export class ConsentController {
  constructor(private readonly consents: ConsentService) {}

  @Get()
  @ApiOperation({ summary: 'Current consent for health data (per source), device usage, notifications, and analytics.' })
  @ApiOkResponse({ type: ConsentStatusResponse, isArray: true })
  async status(@CurrentAuth() auth: AuthContext): Promise<ConsentStatusResponse[]> {
    const statuses = await this.consents.status(auth.userId);
    return statuses.map((status) => ({ ...status, scopes: [...status.scopes] }));
  }

  @Get('history')
  @ApiOperation({ summary: 'Every consent decision of this account, newest first. Decisions are never changed.' })
  @ApiOkResponse({ type: ConsentDecisionResponse, isArray: true })
  async history(@CurrentAuth() auth: AuthContext): Promise<ConsentDecisionResponse[]> {
    return (await this.consents.history(auth.userId)).map(decisionResponse);
  }

  @Post()
  @ApiOperation({
    summary: 'Grant or withdraw consent. A withdrawal stops collection at once and can delete the data collected so far.',
  })
  @ApiCreatedResponse({ type: RecordConsentResponse, description: 'Recorded.' })
  @ApiOkResponse({ type: RecordConsentResponse, description: 'Already recorded; nothing changed.' })
  async record(
    @CurrentAuth() auth: AuthContext,
    @Body() body: RecordConsentRequest,
    @Res({ passthrough: true }) response: StatusSetter,
  ): Promise<RecordConsentResponse> {
    const recorded = await this.consents.record(auth.userId, body);
    response.status(recorded.replayed ? HttpStatus.OK : HttpStatus.CREATED);
    return { decision: decisionResponse(recorded.decision), replayed: recorded.replayed, deletedRecords: recorded.deletedRecords };
  }
}
