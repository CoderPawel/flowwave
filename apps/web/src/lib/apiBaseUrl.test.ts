import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { apiBaseUrl } from './apiBaseUrl.ts';

describe('apiBaseUrl', () => {
  it('accepts HTTPS URLs and normalizes trailing slashes', () => {
    assert.deepEqual(apiBaseUrl('https://api.flowwave.example/'), { ok: true, url: 'https://api.flowwave.example' });
    assert.deepEqual(apiBaseUrl(' https://example.com/api/ '), { ok: true, url: 'https://example.com/api' });
  });

  it('allows plain HTTP only for local development hosts', () => {
    assert.deepEqual(apiBaseUrl('http://localhost:3000'), { ok: true, url: 'http://localhost:3000' });
    assert.deepEqual(apiBaseUrl('http://127.0.0.1:3000'), { ok: true, url: 'http://127.0.0.1:3000' });
    assert.deepEqual(apiBaseUrl('http://api.flowwave.example'), { ok: false, reason: 'insecure' });
  });

  it('rejects missing, malformed, and credential-bearing values', () => {
    assert.deepEqual(apiBaseUrl(undefined), { ok: false, reason: 'missing' });
    assert.deepEqual(apiBaseUrl('  '), { ok: false, reason: 'missing' });
    assert.deepEqual(apiBaseUrl('not a url'), { ok: false, reason: 'invalid' });
    assert.deepEqual(apiBaseUrl('ftp://example.com'), { ok: false, reason: 'invalid' });
    assert.deepEqual(apiBaseUrl('https://user:pass@example.com'), { ok: false, reason: 'invalid' });
    assert.deepEqual(apiBaseUrl('https://example.com/?token=abc'), { ok: false, reason: 'invalid' });
  });
});
