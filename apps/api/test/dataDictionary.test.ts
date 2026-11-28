import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), '../../../..');
const read = (path: string) => readFileSync(join(repoRoot, path), 'utf8');

interface TableColumns {
  readonly table: string;
  readonly columns: readonly string[];
}

function tablesFromSchema(schema: string): TableColumns[] {
  const blocks = [...schema.matchAll(/^model (\w+) \{\n([\s\S]*?)^\}/gm)];
  const modelNames = new Set(blocks.map((block) => block[1]));
  return blocks.map(([, model, body = '']) => {
    const table = /@@map\("([^"]+)"\)/.exec(body)?.[1] ?? model ?? '';
    const columns: string[] = [];
    for (const line of body.split('\n')) {
      const field = /^\s+(\w+)\s+(\w+)(\[\])?\??(.*)$/.exec(line);
      if (!field) continue;
      const [, name = '', type = '', , attributes = ''] = field;
      if (modelNames.has(type)) continue;
      columns.push(/@map\("([^"]+)"\)/.exec(attributes)?.[1] ?? name);
    }
    return { table, columns };
  });
}

function section(markdown: string, table: string): string | undefined {
  const lines = markdown.split('\n');
  const start = lines.findIndex((line) => new RegExp(`^#+ \`${table}\``).test(line));
  if (start === -1) return undefined;
  const level = /^#+/.exec(lines[start] ?? '')?.[0].length ?? 1;
  const end = lines.findIndex((line, index) => index > start && new RegExp(`^#{1,${level}} `).test(line));
  return lines.slice(start, end === -1 ? undefined : end).join('\n');
}

const tables = tablesFromSchema(read('apps/api/prisma/schema.prisma'));
const documents = {
  'docs/data/data-dictionary.md': read('docs/data/data-dictionary.md'),
  'docs/privacy/data-inventory.md': read('docs/privacy/data-inventory.md'),
};

describe('data documentation', () => {
  it('parses every model from the Prisma schema', () => {
    assert.ok(tables.length >= 19);
    assert.deepEqual(tables.find((entry) => entry.table === 'users')?.columns, [
      'id',
      'home_time_zone',
      'sleep_goal_minutes',
      'is_synthetic',
      'created_at_utc',
      'updated_at_utc',
    ]);
  });

  for (const [path, markdown] of Object.entries(documents)) {
    it(`${path} documents every table and column`, () => {
      const missing: string[] = [];
      for (const { table, columns } of tables) {
        const text = section(markdown, table);
        if (text === undefined) {
          missing.push(`${table} (whole table)`);
          continue;
        }
        missing.push(...columns.filter((column) => !text.includes(`\`${column}\``)).map((column) => `${table}.${column}`));
      }
      assert.deepEqual(missing, [], `Add these to ${path}`);
    });
  }

  it('the data dictionary lists no column that does not exist', () => {
    const markdown = documents['docs/data/data-dictionary.md'];
    const unknown: string[] = [];
    for (const { table, columns } of tables) {
      const text = section(markdown, table) ?? '';
      for (const row of text.matchAll(/^\| `(\w+)` \|/gm)) {
        if (!columns.includes(row[1] ?? '')) unknown.push(`${table}.${row[1]}`);
      }
    }
    assert.deepEqual(unknown, []);
  });
});
