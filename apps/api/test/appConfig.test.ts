import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { ConfigValidationError, loadConfig } from '../src/config/appConfig.js';

const DATABASE_URL = 'postgresql://flowwave:s3cret-password@localhost:5432/flowwave';

describe('loadConfig', () => {
  it('applies defaults for optional variables', () => {
    assert.deepEqual(loadConfig({ DATABASE_URL }), {
      environment: 'development',
      port: 3000,
      databaseUrl: DATABASE_URL,
      logLevel: 'info',
      swaggerEnabled: true,
      corsOrigins: [],
      auth: { accessTokenTtlSeconds: 900, refreshTokenTtlDays: 30, registrationEnabled: true },
      trustProxyHops: 0,
      rateLimitEnabled: true,
      backgroundJobsEnabled: true,
    });
  });

  it('parses every supported variable', () => {
    const config = loadConfig({
      NODE_ENV: 'production',
      PORT: '8080',
      DATABASE_URL,
      LOG_LEVEL: 'warn',
      SWAGGER_ENABLED: 'true',
      CORS_ORIGINS: 'https://panel.flowwave.example, http://localhost:3001',
      ACCESS_TOKEN_TTL_SECONDS: '600',
      REFRESH_TOKEN_TTL_DAYS: '14',
      AUTH_REGISTRATION_ENABLED: 'true',
      TRUST_PROXY_HOPS: '1',
      RATE_LIMIT_ENABLED: 'false',
      BACKGROUND_JOBS_ENABLED: 'false',
    });
    assert.deepEqual(config.auth, { accessTokenTtlSeconds: 600, refreshTokenTtlDays: 14, registrationEnabled: true });
    assert.equal(config.trustProxyHops, 1);
    assert.equal(config.rateLimitEnabled, false);
    assert.equal(config.backgroundJobsEnabled, false);
    assert.equal(config.environment, 'production');
    assert.equal(config.port, 8080);
    assert.equal(config.logLevel, 'warn');
    assert.equal(config.swaggerEnabled, true);
    assert.deepEqual(config.corsOrigins, ['https://panel.flowwave.example', 'http://localhost:3001']);
  });

  it('disables Swagger and registration by default in production', () => {
    const config = loadConfig({ NODE_ENV: 'production', DATABASE_URL });
    assert.equal(config.swaggerEnabled, false);
    assert.equal(config.auth.registrationEnabled, false);
  });

  it('reports every invalid variable at once', () => {
    assert.throws(
      () =>
        loadConfig({
          NODE_ENV: 'staging',
          PORT: '99999',
          LOG_LEVEL: 'verbose',
          SWAGGER_ENABLED: 'yes',
          CORS_ORIGINS: 'not-an-origin',
          ACCESS_TOKEN_TTL_SECONDS: '5',
          REFRESH_TOKEN_TTL_DAYS: '365',
          TRUST_PROXY_HOPS: 'all',
        }),
      (error: unknown) => {
        assert.ok(error instanceof ConfigValidationError);
        const text = error.problems.join('\n');
        for (const name of ['NODE_ENV', 'PORT', 'DATABASE_URL', 'LOG_LEVEL', 'SWAGGER_ENABLED', 'CORS_ORIGINS',
          'ACCESS_TOKEN_TTL_SECONDS', 'REFRESH_TOKEN_TTL_DAYS', 'TRUST_PROXY_HOPS']) {
          assert.match(text, new RegExp(name));
        }
        return true;
      },
    );
  });

  it('never echoes provided values in error messages', () => {
    assert.throws(
      () => loadConfig({ DATABASE_URL: 'mysql://flowwave:s3cret-password@localhost/flowwave' }),
      (error: unknown) => error instanceof ConfigValidationError && !error.message.includes('s3cret-password'),
    );
  });
});
