import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  ForbiddenDataError,
  assertNoForbiddenFields,
  findForbiddenFields,
  isForbiddenKey,
} from '../src/index.js';

describe('forbidden data guard', () => {
  it('matches every never-collect category regardless of key style', () => {
    for (const key of ['windowTitle', 'window_title', 'URL', 'pageUrl', 'documentContents', 'message', 'file_name', 'filePath', 'keystrokes', 'Key-Press']) {
      assert.equal(isForbiddenKey(key), true, key);
    }
  });

  it('allows ordinary fields', () => {
    for (const key of ['selfReportedEnergy', 'sleepDurationMinutes', 'recordedAt', 'timeZone', 'focusMinutes']) {
      assert.equal(isForbiddenKey(key), false, key);
    }
  });

  it('reports nested paths without values', () => {
    const payload = {
      energy: 3,
      sessions: [{ minutes: 25 }, { minutes: 30, activeWindow: 'Secret plan.docx' }],
      meta: { device: { url: 'https://example.com' } },
    };
    assert.deepEqual(findForbiddenFields(payload), ['sessions[1].activeWindow', 'meta.device.url']);
    assert.throws(
      () => assertNoForbiddenFields(payload),
      (error: unknown) =>
        error instanceof ForbiddenDataError &&
        error.code === 'forbidden_data' &&
        !error.message.includes('Secret plan') &&
        !error.message.includes('example.com'),
    );
  });

  it('accepts clean payloads, primitives, and cyclic objects', () => {
    assert.doesNotThrow(() => assertNoForbiddenFields({ energy: 4 }));
    assert.doesNotThrow(() => assertNoForbiddenFields(null));
    assert.doesNotThrow(() => assertNoForbiddenFields('text'));
    const cyclic: Record<string, unknown> = { energy: 2 };
    cyclic.self = cyclic;
    assert.doesNotThrow(() => assertNoForbiddenFields(cyclic));
  });
});
