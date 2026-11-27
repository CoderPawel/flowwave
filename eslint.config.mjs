import js from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  {
    ignores: [
      '**/node_modules/**',
      '**/dist/**',
      '**/generated/**',
      'apps/web/**',
      'apps/mobile/**',
      'packages/contracts/src/schema.d.ts',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: {
          allowDefaultProject: ['apps/api/prisma.config.ts'],
        },
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      '@typescript-eslint/consistent-type-imports': ['error', { fixStyle: 'inline-type-imports' }],
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
      // In-memory implementations of async interfaces are intentionally async without awaiting.
      '@typescript-eslint/require-await': 'off',
      'no-console': ['error', { allow: ['error'] }],
    },
  },
  {
    files: ['**/*.mjs', '**/*.js'],
    ...tseslint.configs.disableTypeChecked,
  },
  {
    files: ['**/test/**/*.ts'],
    rules: {
      // node:test describe/it return promises that the runner tracks itself.
      '@typescript-eslint/no-floating-promises': 'off',
    },
  },
  {
    files: ['apps/api/src/**/*.ts'],
    rules: {
      // Nest needs runtime imports of injected classes for decorator metadata.
      '@typescript-eslint/consistent-type-imports': 'off',
    },
  },
  {
    files: ['apps/api/src/scripts/**/*.ts'],
    rules: {
      'no-console': 'off',
    },
  },
);
