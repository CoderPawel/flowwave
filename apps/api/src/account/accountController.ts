import { Body, Controller, Delete, Get, Header, HttpStatus, Param, ParseUUIDPipe, Post, Res } from '@nestjs/common';
import {
  ApiAcceptedResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiForbiddenResponse,
  ApiOkResponse,
  ApiOperation,
  ApiProduces,
  ApiTags,
} from '@nestjs/swagger';
import type { Prisma } from '../../generated/prisma/client.js';
import { CurrentAuth } from '../auth/authGuard.js';
import type { AuthContext } from '../auth/authService.js';
import { AccountResponse, DeleteAccountRequest, DeletionReceiptResponse, ExportJobResponse } from './accountDtos.js';
import { AccountService } from './accountService.js';
import { DataExportService, type ExportJobView } from './dataExportService.js';

interface StatusSetter {
  status(code: number): unknown;
}

function exportJobResponse(job: ExportJobView): ExportJobResponse {
  return {
    id: job.id,
    status: job.status,
    requestedAt: job.requestedAt.toISOString(),
    completedAt: job.completedAt?.toISOString() ?? null,
    expiresAt: job.expiresAt?.toISOString() ?? null,
    failureCode: job.failureCode,
    resultBytes: job.resultBytes,
  };
}

@ApiTags('account')
@ApiBearerAuth()
@Controller('account')
export class AccountController {
  constructor(
    private readonly accounts: AccountService,
    private readonly exports: DataExportService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'The signed-in account.' })
  @ApiOkResponse({ type: AccountResponse })
  async get(@CurrentAuth() auth: AuthContext): Promise<AccountResponse> {
    const account = await this.accounts.get(auth.userId);
    return { ...account, createdAt: account.createdAt.toISOString() };
  }

  @Delete()
  @ApiOperation({ summary: 'Delete the account and all its data at once. Requires the current password; cannot be undone.' })
  @ApiOkResponse({ type: DeletionReceiptResponse })
  @ApiForbiddenResponse({ description: 'Wrong password.' })
  async delete(@CurrentAuth() auth: AuthContext, @Body() body: DeleteAccountRequest): Promise<DeletionReceiptResponse> {
    const receipt = await this.accounts.delete(auth, body.password);
    return { receiptId: receipt.receiptId, deletedAt: receipt.deletedAt.toISOString() };
  }

  @Post('exports')
  @ApiOperation({ summary: 'Request a JSON export of all account data. Returns the open job if one exists.' })
  @ApiAcceptedResponse({ type: ExportJobResponse, description: 'Queued.' })
  @ApiOkResponse({ type: ExportJobResponse, description: 'An export is already queued or running.' })
  async requestExport(
    @CurrentAuth() auth: AuthContext,
    @Res({ passthrough: true }) response: StatusSetter,
  ): Promise<ExportJobResponse> {
    const { job, created } = await this.exports.request(auth.userId);
    response.status(created ? HttpStatus.ACCEPTED : HttpStatus.OK);
    return exportJobResponse(job);
  }

  @Get('exports/:exportId')
  @ApiOperation({ summary: 'Status of an export job.' })
  @ApiOkResponse({ type: ExportJobResponse })
  async getExport(
    @CurrentAuth() auth: AuthContext,
    @Param('exportId', new ParseUUIDPipe()) exportId: string,
  ): Promise<ExportJobResponse> {
    return exportJobResponse(await this.exports.get(auth.userId, exportId));
  }

  @Get('exports/:exportId/download')
  @Header('Content-Disposition', 'attachment; filename="flowwave-export.json"')
  @Header('Cache-Control', 'no-store')
  @ApiProduces('application/json')
  @ApiOperation({ summary: 'Download a completed export (format flowwave-account-export, version 1).' })
  @ApiOkResponse({ description: 'The export file.', schema: { type: 'object' } })
  @ApiConflictResponse({ description: 'Not ready yet, or expired.' })
  async download(
    @CurrentAuth() auth: AuthContext,
    @Param('exportId', new ParseUUIDPipe()) exportId: string,
  ): Promise<Prisma.JsonObject> {
    return this.exports.download(auth.userId, exportId);
  }
}
