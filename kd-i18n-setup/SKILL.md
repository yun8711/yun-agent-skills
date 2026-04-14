---
name: kd-i18n-setup
description: >-
  面向公司内 Vue 2 + webpack 标品前端的国际化改造逐项清单（VoerkaI18n 2.1.13、vue-i18n、Element/KD、RTL、qiankun）。
  以本 Skill 内 templates 为样例，覆盖路由守卫、请求 Accept-Language、顶栏与侧栏等。
  含根目录 .voerkai18nignore 默认基线与 .gitignore 中标注辅助文件（voerkai18n_progress、voerkai18n_literal_hits，勿提交）。
  在用户进行国际化改造、接入 VoerkaI18n 或 vue-i18n、配置 postcss-rtl、做 qiankun 语言同步或需与 rhea-fe 类项目对齐时使用。
---

# 国际化改造清单

## 最小闭环路径（优先打通再逐项细化）

1. 安装并对齐 **`^2.1.13`** 的 `@voerkai18n/cli`、runtime、vue2、loader 等（见下文「依赖」）。
2. 若无 **`src/languages`**，根目录执行 **`voerkai18n init`**。
3. **`vue.config.js`** 为 `src` 下 `js`/`vue` 配上 **voerkai18n-loader**（`enforce: 'pre'`）。
4. **`main.js`** 接入 **`i18nPlugin`**、**VueI18n**（Element/KD 文案）、**`Vue.mixin(i18nMixin)`** 等（见下文「main.js 改造」）。
5. 能成功执行 **`pnpm i18n:extract`** 后，再按需补 **postcss-rtl**、全局样式 ignore、mixin、布局与微前端分支等；不必第一次就改全文件。

## AI 须遵守（执行本清单前读一遍）

- **版本线**：`@voerkai18n/cli`、`@voerkai18n/runtime`、`@voerkai18n/vue2`、`voerkai18n-loader` 均 **`^2.1.13`**，与 CLI 一致；**禁止**混版本、升 **3.x**。
- **禁止**：`voerkai18n apply`；**任何** `@voerkai18n/plugins`。
- **包管理**：优先 **pnpm**。
- **初始化**：若无 **`src/languages/index.js`**，在项目根执行 **`voerkai18n init`**；若 init 后仍缺 **`@voerkai18n/runtime`**，需手动安装。
- **双体系**：业务词条 **Voerka（`t` / `i18nScope`）**；**Element / @kd/components** 走 **VueI18n `i18n.t`**（见 `main.js`）；切语言后常用 **`i18nScope.on('change')` + `reload`** 与现网一致。
- **清单优先与排障**：改造项目须**尽量按本 Skill 清单落地**，**不得**凭主观随意增删、改换清单约定的依赖与配置（文中已写明「按项目」「可选」者除外）。改造后若运行异常，应**优先排查**项目**原有**依赖版本、构建链路（如 `vue.config.js`、loader 顺序、别名路径）、及与微前端等相关的既有配置是否与清单前提一致；**避免**在未核实项目自身问题前，用偏离清单的临时变通替代根因修复。

**执行前可跳过**：全局 `voerkai18n -h` 且为 2.1.13；已有 `languages`、依赖版本已对齐、loader 已挂——对应步骤不必重做。

---

## voerkai18n cli 工具

通过 `voerkai18n -h` 验证是否已全局安装；无则：

```shell
pnpm add -g @voerkai18n/cli@2.1.13
```

## 国际化相关依赖

检查 `package.json` 是否已有下列片段（**版本必须与 CLI 一致 `^2.1.13`**）；缺少则安装并补 scripts。

```json
{
  "scripts": {
    "i18n:extract": "voerkai18n extract -D && prettier --write src/languages/*.*",
    "i18n:compile": "voerkai18n compile && prettier --write src/languages/*.*"
  },
  "dependencies": {
    "@voerkai18n/runtime": "^2.1.13",
    "vue-i18n": "8.28.2"
  },
  "devDependencies": {
    "@voerkai18n/vue2": "^2.1.13",
    "autoprefixer": "^10.4.20",
    "postcss-rtlcss": "^5.7.1",
    "voerkai18n-loader": "^2.1.13"
  }
}
```

## 配置文件

### 配置 vue.config.js

在 `vue.config.js` 中增加（**需** `const path = require('path')` 或与现有写法合并；勿删项目其它配置）：

```javascript
module.exports = {
  configureWebpack: {
    module: {
      rules: [
        {
          test: [/^$/, /\.(js|vue)$/],
          use: [
            {
              loader: 'voerkai18n-loader',
              options: {
                autoImport: true,
                debug: false,
              },
            },
          ],
          include: path.join(__dirname, 'src'),
          enforce: 'pre',
        },
      ],
    },
  },
}
```

**备选**：若项目统一使用 Vue CLI **`chainWebpack`**，可在 **`js` / `vue`** 规则里 **`.use('voerkai18n-loader').loader('voerkai18n-loader').before('babel-loader'|'vue-loader')`**，并设 **相同 `options`**；与链上 loader 冲突时按构建报错微调 `before` 目标。

### 配置 postcss

新建 `postcss.config.js`，全文见：[templates/postcss.config.js](./templates/postcss.config.js)（`autoprefixer` + `postcss-rtlcss`，构建期 RTL）。

### 配置 .voerkai18nignore

在项目**根目录**创建 **`.voerkai18nignore`**，列出**不参与后续自动化标注 / 提取**的路径与模式；**写法与 `.gitignore` 相同**（glob、`/` 结尾表示目录、否定规则 `!`、注释 `#` 等）。

**须在国际化接入或项目发版前就绪**：本文件与 **VoerkaI18n 工具链**（`extract` 等）及 **kd-i18n-marking** 的扫描范围一致，**不得**推迟到「开始标注」时才首次创建；缺省时按下方**默认基线**落盘，再按仓库实际增删条目。

**默认基线**（可按项目增删；与 **kd-i18n-marking** 约定一致）：

```gitignore
# .voerkai18nignore（默认基线，按项目增删）
node_modules
dist
public
*.test.js
*.spec.js
*.scss
*.css
src/assets
src/languages
src/types
src/server
```

标注阶段若需收窄/扩大忽略范围，仍只改此文件并与团队约定同步，不在 **kd-i18n-marking** 内重复维护另一套默认模板。

### 配置 .gitignore（标注辅助文件）

使用 **kd-i18n-marking** 时，会在仓库**根目录**生成 **`voerkai18n_progress.txt`**（分批队列）、**`voerkai18n_literal_hits.txt`**（源语言字面量登记），均为**本地工作文件，不得提交**。在根目录 **`.gitignore`** 中追加（若尚无）：

```gitignore
# VoerkaI18n 标注辅助（kd-i18n-marking，勿提交）
voerkai18n_progress.txt
voerkai18n_literal_hits.txt
```

接入国际化或首次引入标注流程时即写入，避免误将辅助文件推远端。

## 源码改造

### 增加全局变量声明

`src/constants/i18n.js`：

```javascript
// rtl的语言列表
export const rtlLanguages = ['ar']
```

### 增加全局 mixin

在 **`src/mixin/`** 下新增 `i18n-mixin.js`（**路径名以 `mixin` 为准**），全局注入用。全文见：[templates/i18n-mixin.js](./templates/i18n-mixin.js)。**要点（文字）**：包装 `voerkai18nMixin()`；**`isRtl` / `htmlDirection`**、`setLanguage`、`provide`(`htmlDir`,`isRtl`)；同步 **`document.documentElement.dir`** 与根 **` :dir`**；可选 **`getI18nWidth`**。

### 增加全局 directive

- `src/directives/v-column-label.js`：主要解决 **kd-column-action** 未显式 **`label`** 时列头「操作」等；全文：[templates/v-column-label.js](./templates/v-column-label.js)。**注意**：指令名与 **`directives/index.js` 批量注册**一致，避免与文件内重复 `Vue.directive` 冲突。
- `src/directives/index.js`：`require.context` + `install` 注册，见 [templates/directives-index.js](./templates/directives-index.js)。

### 增加全局样式文件

`src/styles/i18n-style.scss`，示例：[templates/i18n-style.scss](./templates/i18n-style.scss)。**收敛意图（文字）**：滚动条等与 gutter 用 **`margin-inline-*`**；对 **sticky 侧栏** 等需 **`/* rtl:begin:ignore */` … `end`** 包住，避免 postcss-rtlcss 误镜像。按项目增删；主样式入口 **最后一行** 引入。

### 全局组件改造

可在 `src/components/index.js` 全局导出（如 **PageTitle**）。

- **svg-icon**，路径 `src/components/svg-icon/index.vue`：postcss-rtl 难处理动态 style，改为 **`marginInlineStart` / `marginInlineEnd`**；见 [templates/svg-icon-index.vue](./templates/svg-icon-index.vue)。
- **page-title**，路径 `src/components/page-title/index.vue`：动态页标题，替换 **kd-page-title**；展示逻辑为「有 title 用 title，否则 `t(routeTitle)`」，`routeTitle` 取自 **`$route.meta.title`**；见 [templates/page-title-index.vue](./templates/page-title-index.vue)。
- **布局 SidebarItem**，路径 `src/layouts/side-bar/SidebarItem.vue`： **`inject: ['isRtl']`**，RTL 下标题区 **margin-right** 替代 **margin-left**；标题 **`this.t(meta.title)`**；见 [templates/SidebarItem.vue](./templates/SidebarItem.vue)。

### 侧栏容器：`src/layouts/side-bar/index.vue`

- 底部折叠区：`svg-icon` 用 **`mr` 等 prop** 替代内联物理 margin（与 **svg-icon** 逻辑边距配合）。
- 底部文案容器 class 避免与全局 **`.text`** 冲突（如 **`sidebar-footer-text`**，样式选择器同步为 **`&-text`**）。
- 保留 **`t('收起菜单')`** 等需翻译文案。

### 顶栏：`src/layouts/nav-head/index.vue`

- 去掉本组件局部的 **`i18nMixin(i18nScope)`**（若曾有），依赖全局 mixin 的 **`changeLanguage` / `activeLanguage` / `setLanguage`**。
- 语言下拉的 **`@change`** → **`languageChange` → `this.setLanguage(lang)`**（勿再手写 **`localStorage` + 单独 `reload`**，与 App 侧 **`i18nScope.on('change')`** 统一）。
- 顶栏菜单项：若 **meta.title** 已是展示文案，可用 **`{{ item.meta.title }}`**；若仍是 key，需 **`t(item.meta.title)`** 或在生成路由 meta 时翻译。

### 路由守卫：`src/router/routerEach.js`

- `import { t } from '@/languages'`。
- 路由守卫 **`catch`**、**`Message.error`** 等默认中文改为 **`t('路由跳转出错')`** 等（可再抽词条）。

### 请求封装：`src/utils/request.js`

- `import { i18nScope, t } from '@/languages'`。
- 响应拦截里兜底 **`t('请求错误')`** 等（硬编码提示统一 **`t()`**）。
- **`setHeaders`**：按 **`i18nScope.activeLanguage`** 设置 **`Accept-Language`**：`zh→zh-CN`、`en→en-US`、`jp→ja-JP`、`ar→ar`。

### App.vue 改造

根节点 **` :dir="htmlDirection"`**；**`mixins: [i18nMixin]`**；**`mounted`**：`i18nScope.on('change', …)` 内 **`window.location.reload()`**；**`created`**：非 qiankun 写 **store `curLanguage`**，qiankun 下 **`onGlobalStateChange`** 收 **`language`** 并 **`setLanguage`**。文档标题、tab 等如仍为硬编码中文，改为 **`t()`** 或统一走 meta。

下文代码块中的 **`inQiankun`、`actions`、`hasProperty`、`receiveMessage`** 等为**项目内既有封装或 qiankun 桥接**，并非通用全局 API；须按当前仓库实现补全 import、替换命名或删减分支，**勿**原样照搬若本项目无对应符号。

```vue
<template>
  <div id="app" :dir="htmlDirection">
    <router-view :key="viewKey"></router-view>
  </div>
</template>
<script>
import { i18nScope } from '@/languages'
import { i18nMixin } from '@/mixin/i18n-mixin'

export default {
  mixins: [i18nMixin],
  mounted() {
    i18nScope.on('change', language => {
      console.log('languageChange', language)
      window.location.reload()
    })
  },
  created() {
    if (!inQiankun) {
      this.$store.commit('global/SET_VALUE', {
        path: 'curLanguage',
        value: this.activeLanguage || 'zh',
      })
    }
    if (inQiankun) {
      actions.onGlobalStateChange(state => {
        if (hasProperty(state, 'language')) {
          const curLanguage = receiveMessage(state, 'language')
          if (curLanguage !== i18nScope.activeLanguage) {
            this.setLanguage(curLanguage)
          }
        }
      }, true)
    }
  },
}
</script>
```

### main.js 改造

合并 **Voerka**（`i18nPlugin` + `i18nScope`）、**VueI18n**（locale 与 Element + KD messages）、**ElementUI** 的 **`i18n: (k,v) => i18n.t(k,v)`**、**`Vue.use(directives)`**、**`Vue.mixin(i18nMixin)`**；根实例 **`{ i18n, router, store, render }`**。微前端保留 **`render(props)`** 封装。

**补充**：纯 SPA 如语言包需就绪后再挂载，可用 **`i18nScope.ready(() => { new Vue({...}).$mount(...) })`**；微前端以现项目为准。

```javascript
import { i18nScope } from "./languages";
import { i18nPlugin } from "@voerkai18n/vue2";
import VueI18n from "vue-i18n";
import zh from "element-ui/lib/locale/lang/zh-CN";
import KdZhCn from "@kd/components/dist/locale/lang/zh-cn";
import en from "element-ui/lib/locale/lang/en";
import KdEn from "@kd/components/dist/locale/lang/en";
import ja from "element-ui/lib/locale/lang/ja";
import KdJa from "@kd/components/dist/locale/lang/ja";
import ar from "element-ui/lib/locale/lang/ar";
// import KdAr from "@kd/components/dist/locale/lang/ar";
import directives from "@/directives";
import { i18nMixin } from "@/mixin/i18n-mixin";

Vue.use(i18nPlugin, { i18nScope });
Vue.use(ElementUI, { size: "small", i18n: (key, value) => i18n.t(key, value) });

Vue.use(VueI18n);
Vue.use(directives);
Vue.mixin(i18nMixin);
const i18n = new VueI18n({
  locale: localStorage.getItem("language"),
  messages: {
    en: { ...en, ...KdEn },
    zh: { ...zh, ...KdZhCn },
    jp: { ...ja, ...KdJa },
    ar: { ...ar /* , ...KdAr */ },
  },
});

let instance = null;

function render(props = {}) {
  instance = new Vue({
    i18n,
    router,
    store,
    render: (h) => h(App),
  }).$mount("#app");
}
```

---

## AI 实施注意（收束）

- **`<html dir>` 与 `:dir`、postcss-rtl、scss ignore**：以 **i18n-mixin** 为同步源，侧栏 **isRtl + svg-icon 逻辑边距 + ignore 块** 组合，缺一会错位。
- **请求语区**：**`Accept-Language`** 与 **`i18nScope.activeLanguage`** 一致。
- 更多词条工作流 → **kd-i18n-marking**、**kd-i18n-translation**（含 compile；完成后 kd-i18n 流程结束，无 styling 子 Skill）。非 Vue CLI（Vite 等）loader 另配，本清单不展开。
