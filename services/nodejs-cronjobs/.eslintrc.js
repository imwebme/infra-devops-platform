module.exports = {
  env: {
    es6: true,
    node: true,
    browser: true,
    commonjs: true,
  },
  parser: 'babel-eslint',
  extends: [
    'airbnb',
    // 'prettier/react',
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:prettier/recommended',
  ],
  rules: {
    'no-use-before-define': 'off',
    'no-unused-vars': 'off',
    'react/jsx-filename-extension': [
      'error',
      {
        extensions: ['.js', 'jsx'],
        // jsx 코드가 가능한 확장자명
      },
    ],
    'prettier/prettier': [
      'error',
      {
        endOfLine: 'auto',
      },
    ],
    'react/react-in-jsx-scope': 'off',
    // airbnb 형식에서 변경하여 덮어쓸 규칙 설정
    'import/no-named-as-default': 0,
    'import/no-named-as-default-member': 0,
    'no-console': 'off',
    'no-shadow': 'off',
    'import/order': 'off',
    'consistent-return': 'off',
    'no-underscore-dangle': 'off',
    'class-methods-use-this': 'off',
    'no-await-in-loop': 'off',
    'react/prop-types': 'off',
    'no-restricted-syntax': 'off',
    'lines-between-class-members': [
      'error',
      'always',
      { exceptAfterSingleLine: true },
    ],
    'no-param-reassign': 'off',
    'default-param-last': 'off',
    'no-promise-executor-return': 'off',
    'func-names': 'off',
    'no-unsafe-optional-chaining': 'off',
    'no-continue': 'off',
    // 'max-len': ['error', { code: 500 }],
  },
}
