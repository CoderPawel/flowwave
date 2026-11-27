import { plainToInstance, Transform } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsOptional, IsString, Matches, Max, Min, validateSync } from 'class-validator';

export const APP_CONFIG = Symbol('APP_CONFIG');

export const ENVIRONMENTS = ['development', 'test', 'production'] as const;
export type Environment = (typeof ENVIRONMENTS)[number];

export const LOG_LEVELS = ['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent'] as const;
export type LogLevel = (typeof LOG_LEVELS)[number];

export interface AppConfig {
  readonly environment: Environment;
  readonly port: number;
  readonly databaseUrl: string;
  readonly logLevel: LogLevel;
  readonly swaggerEnabled: boolean;
  readonly corsOrigins: readonly string[];
}

const toBoolean = ({ value }: { value: unknown }): unknown => {
  if (value === undefined || value === '') return undefined;
  if (value === 'true' || value === true) return true;
  if (value === 'false' || value === false) return false;
  return value;
};

const toInteger = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' && /^\d+$/.test(value) ? Number(value) : value;

const toList = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string'
    ? value
        .split(',')
        .map((item) => item.trim())
        .filter((item) => item.length > 0)
    : value;

class EnvironmentVariables {
  @IsIn(ENVIRONMENTS, { message: `NODE_ENV must be one of: ${ENVIRONMENTS.join(', ')}` })
  NODE_ENV: string = 'development';

  @Transform(toInteger)
  @IsInt({ message: 'PORT must be an integer' })
  @Min(1, { message: 'PORT must be between 1 and 65535' })
  @Max(65535, { message: 'PORT must be between 1 and 65535' })
  PORT: number = 3000;

  @IsString({ message: 'DATABASE_URL is required' })
  @Matches(/^postgres(ql)?:\/\/\S+$/, { message: 'DATABASE_URL must be a postgresql:// connection string' })
  DATABASE_URL!: string;

  @IsIn(LOG_LEVELS, { message: `LOG_LEVEL must be one of: ${LOG_LEVELS.join(', ')}` })
  LOG_LEVEL: string = 'info';

  @Transform(toBoolean)
  @IsOptional()
  @IsBoolean({ message: 'SWAGGER_ENABLED must be "true" or "false"' })
  SWAGGER_ENABLED: boolean | undefined;

  @Transform(toList)
  @Matches(/^https?:\/\/[^\s/]+$/, { each: true, message: 'CORS_ORIGINS must be a comma-separated list of origins like https://app.example.com' })
  CORS_ORIGINS: string[] = [];
}

export class ConfigValidationError extends Error {
  /** Messages name the variable and the rule, never the provided value. */
  constructor(readonly problems: readonly string[]) {
    super(`Invalid configuration:\n- ${problems.join('\n- ')}`);
    this.name = 'ConfigValidationError';
  }
}

/** Validates environment variables once at startup. Throws `ConfigValidationError`. */
export function loadConfig(env: Readonly<Record<string, string | undefined>>): AppConfig {
  const plain = Object.fromEntries(Object.entries(env).filter(([, value]) => value !== undefined));
  const variables = plainToInstance(EnvironmentVariables, plain, { exposeDefaultValues: true });
  const errors = validateSync(variables);
  const problems = errors.flatMap((error) => Object.values(error.constraints ?? {}));

  if (problems.length > 0) {
    throw new ConfigValidationError(problems);
  }

  const environment = variables.NODE_ENV as Environment;
  return {
    environment,
    port: variables.PORT,
    databaseUrl: variables.DATABASE_URL,
    logLevel: variables.LOG_LEVEL as LogLevel,
    swaggerEnabled: variables.SWAGGER_ENABLED ?? environment !== 'production',
    corsOrigins: variables.CORS_ORIGINS,
  };
}
