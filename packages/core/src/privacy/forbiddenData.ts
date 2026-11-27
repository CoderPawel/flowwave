import { ForbiddenDataError } from '../errors.js';

/**
 * Categories FlowWave never collects, with the key spellings that identify
 * them. Keys are compared after lowercasing and removing non-alphanumerics, so
 * `window_title`, `windowTitle` and `Window-Title` all match `windowtitle`.
 *
 * This is a safety net behind allowlisted ingest schemas, not a substitute.
 */
export const FORBIDDEN_DATA_KEYS: Readonly<Record<string, readonly string[]>> = {
  window_titles: ['windowtitle', 'windowtitles', 'windowname', 'activewindow', 'apptitle'],
  urls: ['url', 'urls', 'uri', 'href', 'pageurl', 'taburl', 'browserurl', 'visitedurl', 'link'],
  document_contents: ['documentcontent', 'documentcontents', 'documenttext', 'filecontent', 'filecontents'],
  messages: ['message', 'messages', 'messagebody', 'messagetext', 'messagecontent', 'chatmessage', 'emailbody'],
  file_names: ['filename', 'filenames', 'filepath', 'filepaths', 'documentname', 'documentpath'],
  keystrokes: ['keystroke', 'keystrokes', 'keypress', 'keypresses', 'keylog', 'typedtext', 'keyboardinput'],
};

const FORBIDDEN_KEY_SET: ReadonlySet<string> = new Set(Object.values(FORBIDDEN_DATA_KEYS).flat());

function normalizeKey(key: string): string {
  return key.toLowerCase().replace(/[^a-z0-9]/g, '');
}

export function isForbiddenKey(key: string): boolean {
  return FORBIDDEN_KEY_SET.has(normalizeKey(key));
}

/** Returns the paths of every forbidden key in `payload`, without their values. */
export function findForbiddenFields(payload: unknown): string[] {
  const found: string[] = [];
  const seen = new WeakSet<object>();

  const visit = (value: unknown, path: string): void => {
    if (typeof value !== 'object' || value === null) return;
    if (seen.has(value)) return;
    seen.add(value);

    if (Array.isArray(value)) {
      value.forEach((item, index) => visit(item, `${path}[${index}]`));
      return;
    }
    for (const [key, child] of Object.entries(value)) {
      const childPath = path ? `${path}.${key}` : key;
      if (isForbiddenKey(key)) {
        found.push(childPath);
      }
      visit(child, childPath);
    }
  };

  visit(payload, '');
  return found;
}

export function assertNoForbiddenFields(payload: unknown): void {
  const paths = findForbiddenFields(payload);
  if (paths.length > 0) {
    throw new ForbiddenDataError(paths);
  }
}
