import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseUUIDPipe, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { RateLimit } from '../rateLimit/rateLimitGuard.js';
import {
  LoginRequest,
  LogoutAllResponse,
  RefreshRequest,
  RegisterRequest,
  SessionResponse,
  TokenResponse,
} from './authDtos.js';
import { CurrentAuth, Public } from './authGuard.js';
import { AuthService, type AuthContext, type IssuedTokens } from './authService.js';

function tokenResponse(tokens: IssuedTokens): TokenResponse {
  return {
    tokenType: 'Bearer',
    accessToken: tokens.accessToken,
    accessTokenExpiresAt: tokens.accessTokenExpiresAt.toISOString(),
    refreshToken: tokens.refreshToken,
    refreshTokenExpiresAt: tokens.refreshTokenExpiresAt.toISOString(),
    userId: tokens.userId,
    sessionId: tokens.sessionId,
    deviceId: tokens.deviceId,
  };
}

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  @Public()
  @RateLimit('auth.register')
  @ApiOperation({ summary: 'Create an account with email and password (development authentication, decision 0013).' })
  @ApiCreatedResponse({ type: TokenResponse })
  @ApiConflictResponse({ description: 'An account with this email already exists.' })
  @ApiTooManyRequestsResponse()
  async register(@Body() body: RegisterRequest): Promise<TokenResponse> {
    return tokenResponse(await this.auth.register(body));
  }

  @Post('login')
  @Public()
  @HttpCode(HttpStatus.OK)
  @RateLimit('auth.login')
  @ApiOperation({ summary: 'Sign in. Wrong passwords and unknown emails get the same 401.' })
  @ApiOkResponse({ type: TokenResponse })
  @ApiUnauthorizedResponse()
  @ApiTooManyRequestsResponse()
  async login(@Body() body: LoginRequest): Promise<TokenResponse> {
    return tokenResponse(await this.auth.login(body));
  }

  @Post('refresh')
  @Public()
  @HttpCode(HttpStatus.OK)
  @RateLimit('auth.refresh')
  @ApiOperation({ summary: 'Exchange a refresh token for a new pair. Reusing a refresh token signs the device out.' })
  @ApiOkResponse({ type: TokenResponse })
  @ApiUnauthorizedResponse()
  async refresh(@Body() body: RefreshRequest): Promise<TokenResponse> {
    return tokenResponse(await this.auth.refresh(body.refreshToken));
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Sign out this device.' })
  @ApiNoContentResponse()
  async logout(@CurrentAuth() auth: AuthContext): Promise<void> {
    await this.auth.logout(auth);
  }

  @Post('logout-all')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Sign out every device of this account, including this one.' })
  @ApiOkResponse({ type: LogoutAllResponse })
  async logoutAll(@CurrentAuth() auth: AuthContext): Promise<LogoutAllResponse> {
    return { sessionsRevoked: await this.auth.logoutAll(auth) };
  }

  @Get('sessions')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Devices currently signed in to this account.' })
  @ApiOkResponse({ type: SessionResponse, isArray: true })
  async sessions(@CurrentAuth() auth: AuthContext): Promise<SessionResponse[]> {
    const sessions = await this.auth.listSessions(auth);
    return sessions.map((session) => ({
      ...session,
      createdAt: session.createdAt.toISOString(),
      lastRefreshedAt: session.lastRefreshedAt?.toISOString() ?? null,
    }));
  }

  @Post('sessions/:sessionId/revoke')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Sign out another device of this account.' })
  @ApiNoContentResponse()
  async revokeSession(
    @CurrentAuth() auth: AuthContext,
    @Param('sessionId', new ParseUUIDPipe()) sessionId: string,
  ): Promise<void> {
    await this.auth.revokeSession(auth, sessionId);
  }
}
