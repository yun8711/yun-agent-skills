# package.json文件模板

说明：

- name：应与实际项目名称相符
- version：应与实际分支中的版本号一致，推荐遵循semver语义化版本号规范
- description：应与实际项目模块、功能相符
- scripts：模板中包含满足基本的开发需求的命令，可按需自动添加
- dependencies和devDependencies：包含团队中前端项目的基本依赖及部分常用功能的依赖，如echarts（图表插件）、vue-clipboard2（复制功能库），可自定按需增删
- lint-staged：用于代码提交时触发代码格式化、提交信息校验
- browserslist：声明需要兼容的浏览器版本信息
- engines：声明项目对运行环境的版本要求，安装不兼容的依赖时会发出警告

```JSON
{
  "name": "tds-platform",
  "version": "3.0.0",
  "private": true,
  "description": "可信数据空间服务平台",
  "scripts": {
    "preinstall": "npx only-allow pnpm",
    "serve": "vue-cli-service serve",
    "build": "vue-cli-service build",
    "report": "vue-cli-service build --report",
    "lint": "vue-cli-service lint",
    "lint:style": "stylelint src/**/*.{html,vue,css,scss} --fix --custom-syntax postcss-scss",
    "prepare": "husky install",
    "generate-api": "node scripts/api-generator.js && eslint --fix src/api"
  },
  "main": "index.js",
  "dependencies": {
    "@kd/components": "4.0.10",
    "@microsoft/fetch-event-source": "^2.0.1",
    "@visactor/vtable": "^1.22.10",
    "axios": "^1.13.2",
    "core-js": "^3.47.0",
    "cron-parser": "^4.9.0",
    "echarts": "5.4.1",
    "element-ui": "^2.15.14",
    "jsencrypt": "^3.5.4",
    "lodash": "^4.17.21",
    "normalize.css": "^8.0.1",
    "nprogress": "^0.2.0",
    "path-browserify-esm": "^1.0.6",
    "qs": "^6.14.1",
    "sortablejs": "^1.15.6",
    "vue": "2.6.14",
    "vue-clipboard2": "^0.3.3",
    "vue-router": "3.5.4",
    "vue-virtual-scroll-list": "^2.3.5",
    "vuex": "3.6.2"
  },
  "devDependencies": {
    "@babel/core": "^7.28.5",
    "@babel/eslint-parser": "^7.28.5",
    "@commitlint/cli": "^17.8.1",
    "@commitlint/config-conventional": "^17.8.1",
    "@types/node": "20.16.0",
    "@vue/cli-plugin-babel": "~5.0.9",
    "@vue/cli-plugin-eslint": "~5.0.9",
    "@vue/cli-plugin-router": "~5.0.9",
    "@vue/cli-plugin-vuex": "~5.0.9",
    "@vue/cli-service": "~5.0.9",
    "code-inspector-plugin": "^0.9.3",
    "eslint": "^7.32.0",
    "eslint-config-prettier": "^8.10.2",
    "eslint-plugin-prettier": "^4.2.5",
    "eslint-plugin-vue": "^9.33.0",
    "husky": "^8.0.3",
    "lint-staged": "13.0.0",
    "postcss": "8.4.32",
    "postcss-html": "^1.8.0",
    "postcss-scss": "^4.0.9",
    "prettier": "^2.8.8",
    "sass": "^1.97.2",
    "sass-loader": "^12.6.0",
    "stylelint": "14.14.1",
    "stylelint-config-prettier": "^9.0.5",
    "stylelint-config-recess-order": "^3.1.0",
    "stylelint-config-recommended": "9.0.0",
    "stylelint-config-recommended-scss": "^8.0.0",
    "stylelint-config-recommended-vue": "^1.6.1",
    "stylelint-config-standard": "^29.0.0",
    "stylelint-order": "^5.0.0",
    "stylelint-scss": "^4.7.0",
    "svg-sprite-loader": "^6.0.11",
    "svgo-loader": "^4.0.0",
    "vue-template-compiler": "2.6.14",
    "webpack": "^5.104.1"
  },
  "lint-staged": {
    "*.{js,jsx,vue}": "eslint --fix",
    "*.{html,vue,css,scss}": "stylelint --fix --allow-empty-input"
  },
  "browserslist": [
    "chrome >= 91"
  ],
  "engines": {
    "node": ">=16.0.0",
    "pnpm": ">=10.2.1"
  },
  "pnpm": {
    "onlyBuiltDependencies": [
      "@parcel/watcher",
      "core-js",
      "yorkie"
    ]
  }
}
```