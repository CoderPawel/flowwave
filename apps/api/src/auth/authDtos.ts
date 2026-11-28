import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsIn, IsOptional, IsString, Matches, MaxLength, MinLength, ValidateNested } from 'class-validator';
import { DevicePlatform } from '../../generated/prisma/enums.js';
import { PASSWORD_MAX_LENGTH, PASSWORD_MIN_LENGTH } from './passwordHasher.js';

const PLATFORMS = Object.values(DevicePlatform);

export class DeviceInfoDto {
  @ApiProperty({ enum: PLATFORMS, example: 'android' })
  @IsIn(PLATFORMS)
  readonly platform!: DevicePlatform;

  @ApiPropertyOptional({ example: '0.1.0', maxLength: 32 })
  @IsOptional()
  @IsString()
  @Matches(/^[0-9A-Za-z.+-]{1,32}$/, { message: 'appVersion must be a version like 0.1.0' })
  readonly appVersion?: string;
}

export class RegisterRequest {
  @ApiProperty({ example: 'tester@example.org', maxLength: 254 })
  @IsString()
  @MaxLength(254)
  readonly email!: string;

  @ApiProperty({ minLength: PASSWORD_MIN_LENGTH, maxLength: PASSWORD_MAX_LENGTH, format: 'password' })
  @IsString()
  @MinLength(PASSWORD_MIN_LENGTH)
  @MaxLength(PASSWORD_MAX_LENGTH)
  readonly password!: string;

  @ApiProperty({ example: 'Europe/Budapest', description: 'IANA time zone used to group days.' })
  @IsString()
  @MaxLength(64)
  readonly homeTimeZone!: string;

  @ApiProperty({ type: DeviceInfoDto })
  @ValidateNested()
  @Type(() => DeviceInfoDto)
  readonly device!: DeviceInfoDto;
}

export class LoginRequest {
  @ApiProperty({ example: 'tester@example.org', maxLength: 254 })
  @IsString()
  @MaxLength(254)
  readonly email!: string;

  @ApiProperty({ format: 'password', maxLength: PASSWORD_MAX_LENGTH * 4 })
  @IsString()
  @MinLength(1)
  @MaxLength(PASSWORD_MAX_LENGTH * 4)
  readonly password!: string;

  @ApiProperty({ type: DeviceInfoDto })
  @ValidateNested()
  @Type(() => DeviceInfoDto)
  readonly device!: DeviceInfoDto;
}

export class RefreshRequest {
  @ApiProperty({ description: 'Single-use refresh token (prefix fwrt_).' })
  @IsString()
  @MaxLength(100)
  readonly refreshToken!: string;
}

export class TokenResponse {
  @ApiProperty({ enum: ['Bearer'] })
  readonly tokenType!: 'Bearer';

  @ApiProperty({ description: 'Short-lived access token (prefix fwat_).' })
  readonly accessToken!: string;

  @ApiProperty({ format: 'date-time' })
  readonly accessTokenExpiresAt!: string;

  @ApiProperty({ description: 'Single-use refresh token (prefix fwrt_). Store only in secure storage.' })
  readonly refreshToken!: string;

  @ApiProperty({ format: 'date-time' })
  readonly refreshTokenExpiresAt!: string;

  @ApiProperty({ format: 'uuid' })
  readonly userId!: string;

  @ApiProperty({ format: 'uuid' })
  readonly sessionId!: string;

  @ApiProperty({ format: 'uuid' })
  readonly deviceId!: string;
}

export class SessionResponse {
  @ApiProperty({ format: 'uuid' })
  readonly id!: string;

  @ApiProperty({ format: 'uuid' })
  readonly deviceId!: string;

  @ApiProperty({ enum: PLATFORMS })
  readonly platform!: DevicePlatform;

  @ApiProperty({ type: String, nullable: true })
  readonly appVersion!: string | null;

  @ApiProperty({ format: 'date-time' })
  readonly createdAt!: string;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  readonly lastRefreshedAt!: string | null;

  @ApiProperty({ description: 'True for the session making this request.' })
  readonly current!: boolean;
}

export class LogoutAllResponse {
  @ApiProperty({ example: 2 })
  readonly sessionsRevoked!: number;
}
