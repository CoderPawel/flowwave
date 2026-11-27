/**
 * Data the user enters directly in FlowWave. Not an external source, so it
 * needs no separate consent, but it is still listed in the data inventory.
 */
export const INTERNAL_DATA_SOURCES = ['manual_check_in'] as const;
export type InternalDataSourceId = (typeof INTERNAL_DATA_SOURCES)[number];

export interface ExternalDataSourceDefinition {
  readonly displayName: string;
  /** The only data categories FlowWave may read from this source, once consented. */
  readonly scopes: readonly string[];
}

/**
 * External sources FlowWave may integrate with. Declaring a source here does
 * not collect anything; an adapter must also exist and call `assertConsent`.
 * Adding a source or scope requires a data-inventory row and a decision note.
 */
export const EXTERNAL_DATA_SOURCES = {
  apple_health: {
    displayName: 'Apple Health',
    scopes: ['sleep_duration'],
  },
  health_connect: {
    displayName: 'Health Connect',
    scopes: ['sleep_duration'],
  },
} as const satisfies Record<string, ExternalDataSourceDefinition>;

export type ExternalDataSourceId = keyof typeof EXTERNAL_DATA_SOURCES;
export type ExternalDataScope<S extends ExternalDataSourceId = ExternalDataSourceId> =
  (typeof EXTERNAL_DATA_SOURCES)[S]['scopes'][number];

export type DataSourceId = InternalDataSourceId | ExternalDataSourceId;

export function isExternalDataSourceId(value: unknown): value is ExternalDataSourceId {
  return typeof value === 'string' && Object.hasOwn(EXTERNAL_DATA_SOURCES, value);
}

export function isDataSourceId(value: unknown): value is DataSourceId {
  return (
    isExternalDataSourceId(value) ||
    (typeof value === 'string' && (INTERNAL_DATA_SOURCES as readonly string[]).includes(value))
  );
}
