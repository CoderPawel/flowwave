import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { CONSENT_TYPES, EXTERNAL_DATA_SOURCES, type ConsentStatus, type ConsentType } from '@flowwave/core';

const SOURCE_IDS = Object.keys(EXTERNAL_DATA_SOURCES);
const STATES = ['granted', 'revoked'] as const;
const STATUSES: readonly ConsentStatus[] = ['granted', 'revoked', 'not_asked', 'outdated'];

export class ZonedTimestampDto {
  @ApiProperty({ example: '2026-11-28T09:00:00.000Z', description: 'UTC instant ending in Z.' })
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,3})?Z$/, { message: 'utc must be an ISO 8601 UTC instant' })
  readonly utc!: string;

  @ApiProperty({ example: 'Europe/Budapest' })
  @IsString()
  @MaxLength(64)
  readonly timeZone!: string;

  @ApiProperty({ example: 60, description: 'Offset in minutes in effect in timeZone at utc.' })
  @IsInt()
  readonly utcOffsetMinutes!: number;
}

export class RecordConsentRequest {
  @ApiProperty({ format: 'uuid', description: 'Generated on the device; repeating the same decision is safe.' })
  @IsUUID()
  readonly id!: string;

  @ApiProperty({ enum: CONSENT_TYPES })
  @IsIn(CONSENT_TYPES)
  readonly type!: ConsentType;

  @ApiPropertyOptional({ enum: SOURCE_IDS, nullable: true, description: 'Required for health_data; absent for other types.' })
  @IsOptional()
  @IsIn(SOURCE_IDS)
  readonly sourceId?: string | null;

  @ApiProperty({ enum: STATES })
  @IsIn(STATES)
  readonly state!: (typeof STATES)[number];

  @ApiProperty({ type: [String], example: ['steps', 'heart_rate'], description: 'Health data scopes; empty otherwise.' })
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  @MaxLength(63, { each: true })
  readonly scopes!: string[];

  @ApiProperty({ example: '2026-11-28', description: 'Version of the consent text the user saw.' })
  @IsString()
  @MaxLength(32)
  readonly policyVersion!: string;

  @ApiProperty({ type: ZonedTimestampDto })
  @ValidateNested()
  @Type(() => ZonedTimestampDto)
  readonly decidedAt!: ZonedTimestampDto;

  @ApiPropertyOptional({ description: 'With a withdrawal of health_data or device_usage: also delete the data collected so far.' })
  @IsOptional()
  @IsBoolean()
  readonly deleteCollectedData?: boolean;
}

export class ConsentDecisionResponse {
  @ApiProperty({ format: 'uuid' })
  readonly id!: string;

  @ApiProperty({ enum: CONSENT_TYPES })
  readonly type!: ConsentType;

  @ApiProperty({ enum: SOURCE_IDS, nullable: true, type: String })
  readonly sourceId!: string | null;

  @ApiProperty({ enum: STATES })
  readonly state!: (typeof STATES)[number];

  @ApiProperty({ type: [String] })
  readonly scopes!: string[];

  @ApiProperty()
  readonly policyVersion!: string;

  @ApiProperty({ type: ZonedTimestampDto })
  readonly decidedAt!: ZonedTimestampDto;
}

export class RecordConsentResponse {
  @ApiProperty({ type: ConsentDecisionResponse })
  readonly decision!: ConsentDecisionResponse;

  @ApiProperty({ description: 'True when this decision had already been recorded.' })
  readonly replayed!: boolean;

  @ApiProperty({ description: 'Records deleted because of deleteCollectedData.' })
  readonly deletedRecords!: number;
}

export class ConsentStatusResponse {
  @ApiProperty({ enum: CONSENT_TYPES })
  readonly type!: ConsentType;

  @ApiProperty({ enum: SOURCE_IDS, nullable: true, type: String })
  readonly sourceId!: string | null;

  @ApiProperty({ enum: STATUSES, description: 'outdated: granted under an older consent text; ask again.' })
  readonly status!: ConsentStatus;

  @ApiProperty({ type: [String] })
  readonly scopes!: string[];

  @ApiProperty({ type: String, nullable: true })
  readonly policyVersion!: string | null;

  @ApiProperty()
  readonly currentPolicyVersion!: string;

  @ApiProperty({ type: ZonedTimestampDto, nullable: true })
  readonly decidedAt!: ZonedTimestampDto | null;
}
