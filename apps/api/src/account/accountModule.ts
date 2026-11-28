import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/authModule.js';
import { BackgroundJobs } from '../maintenance/backgroundJobs.js';
import { RetentionService } from '../maintenance/retentionService.js';
import { AccountController } from './accountController.js';
import { AccountService } from './accountService.js';
import { DataExportService } from './dataExportService.js';

@Module({
  imports: [AuthModule],
  controllers: [AccountController],
  providers: [AccountService, DataExportService, RetentionService, BackgroundJobs],
  exports: [DataExportService, RetentionService],
})
export class AccountModule {}
