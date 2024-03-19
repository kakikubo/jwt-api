const OFF = 0; const WARN = 1; const ERROR = 2

module.exports = {
  root: true,
  env: {
    browser: true,
    node: true
  },
  parserOptions: {
    parser: '@babel/eslint-parser',
    requireConfigFile: false
  },
  extends: [
    '@nuxtjs',
    'eslint:recommended',
    'plugin:nuxt/recommended'
  ],
  plugins: [
  ],
  // add your custom rules here
  rules: {
    'no-path-concat': ERROR,
    'sort-vars': OFF,
    quotes: [WARN, 'single'],
    'vue/multi-word-component-names': 'off'
  }
}
