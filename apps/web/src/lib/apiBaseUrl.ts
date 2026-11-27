export type ApiBaseUrl = { ok: true; url: string } | { ok: false; reason: 'missing' | 'invalid' | 'insecure' };

const LOCAL_HOSTS = new Set(['localhost', '127.0.0.1', '[::1]']);

/**
 * Validates the API base URL from configuration. HTTPS is required except for
 * local development hosts, so session cookies are never sent in cleartext.
 */
export function apiBaseUrl(value: string | undefined): ApiBaseUrl {
  if (value === undefined || value.trim() === '') {
    return { ok: false, reason: 'missing' };
  }
  let url: URL;
  try {
    url = new URL(value.trim());
  } catch {
    return { ok: false, reason: 'invalid' };
  }
  if (url.protocol !== 'https:' && url.protocol !== 'http:') {
    return { ok: false, reason: 'invalid' };
  }
  if (url.protocol === 'http:' && !LOCAL_HOSTS.has(url.hostname)) {
    return { ok: false, reason: 'insecure' };
  }
  if (url.search !== '' || url.hash !== '' || url.username !== '' || url.password !== '') {
    return { ok: false, reason: 'invalid' };
  }
  return { ok: true, url: url.origin + url.pathname.replace(/\/+$/, '') };
}
