import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { ExportJobStatus } from '../../generated/prisma/enums.js';
import { PASSWORD_MAX_LENGTH } from '../auth/passwordHasher.js';

export class AccountResponse {
  @ApiProperty({ format: 'uuid' })
  readonly userId!: string;

  @ApiProperty({ type: String, nullable: true })
  readonly email!: string | null;

  @ApiProperty({ example: 'Europe/Budapest' })
  readonly homeTimeZone!: string;

  @ApiProperty({ type: Number, nullable: true, description: 'Null until the user sets a goal.' })
  readonly sleepGoalMinutes!: number | null;

  @ApiProperty({ format: 'date-time' })
  readonly createdAt!: string;
}

export class DeleteAccountRequest {
  @ApiProperty({ format: 'password', description: 'Current password, required to confirm deletion.' })
  @IsString()
  @MinLength(1)
  @MaxLength(PASSWORD_MAX_LENGTH * 4)
  readonly password!: string;
}

export class DeletionReceiptResponse {
  @ApiProperty({ format: 'uuid', description: 'Keep this ID as proof of deletion.' })
  readonly receiptId!: string;

  @ApiProperty({ format: 'date-time' })
  readonly deletedAt!: string;
}

export class ExportJobResponse {
  @ApiProperty({ format: 'uuid' })
  readonly id!: string;

  @ApiProperty({ enum: Object.values(ExportJobStatus) })
  readonly status!: ExportJobStatus;

  @ApiProperty({ format: 'date-time' })
  readonly requestedAt!: string;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  readonly completedAt!: string | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true, description: 'The download is removed after this.' })
  readonly expiresAt!: string | null;

  @ApiProperty({ type: String, nullable: true, example: 'export_failed' })
  readonly failureCode!: string | null;

  @ApiProperty({ type: Number, nullable: true })
  readonly resultBytes!: number | null;
}
