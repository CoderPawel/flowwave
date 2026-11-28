import {
  type CanActivate,
  createParamDecorator,
  type ExecutionContext,
  Injectable,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthService, type AuthContext } from './authService.js';
import { bearerToken } from './tokens.js';

const PUBLIC_KEY = 'flowwave:public';

/** Opts a route out of authentication. Every other route requires an access token. */
export const Public = () => SetMetadata(PUBLIC_KEY, true);

interface RequestWithAuth {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  auth?: AuthContext;
}

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly auth: AuthService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (context.getType() !== 'http') return true;
    const isPublic = this.reflector.getAllAndOverride<boolean | undefined>(PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;
    const request = context.switchToHttp().getRequest<RequestWithAuth>();
    const header = request.headers['authorization'];
    request.auth = await this.auth.authenticate(bearerToken(typeof header === 'string' ? header : undefined));
    return true;
  }
}

/** The authenticated caller, set by `AuthGuard`. */
export const CurrentAuth = createParamDecorator((_data: unknown, context: ExecutionContext): AuthContext => {
  const auth = context.switchToHttp().getRequest<RequestWithAuth>().auth;
  if (!auth) {
    throw new Error('CurrentAuth used on a public route.');
  }
  return auth;
});
