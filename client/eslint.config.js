import js from '@eslint/js'
import globals from 'globals'
import pluginVue from 'eslint-plugin-vue'
import vueTsEslintConfig from '@vue/eslint-config-typescript'

export default [
  {
    name: 'app/files-to-lint',
    files: ['**/*.{ts,mts,tsx,vue}'],
  },
  {
    name: 'app/files-to-ignore',
    ignores: ['**/dist/**', '**/dist-ssr/**', '**/coverage/**', '**/parity/**'],
  },
  js.configs.recommended,
  ...pluginVue.configs['flat/essential'],
  ...vueTsEslintConfig(),
  {
    // App code runs in the browser.
    name: 'app/browser-globals',
    files: ['src/**/*.{ts,mts,tsx,vue}'],
    languageOptions: {
      globals: { ...globals.browser },
    },
  },
  {
    // Parity/tooling scripts and build config run in Node — but the parity
    // scripts also ship page.evaluate() callbacks that run in the browser, so
    // both global sets are legitimately in scope here.
    name: 'app/node-globals',
    files: ['scripts/**/*.{js,mjs,cjs}', '*.config.{js,cjs,mjs}', '*.config.ts'],
    languageOptions: {
      globals: { ...globals.node, ...globals.browser },
      sourceType: 'module',
    },
    rules: {
      '@typescript-eslint/no-require-imports': 'off',
    },
  },
  {
    rules: {
      'vue/multi-word-component-names': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    }
  }
]
