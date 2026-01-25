# 项目目录结构规范

前端项目需要遵循以下结构

- xxx、yyy 表示任意命名，不是强制要求
- 强制：表示项目中必须存在该目录，且命名必须一致
- 推荐：表示建议存在该目录，命名最好保持一致
- 可选：表示按需实现，不做要求
- 其他未标识的，按可选处理

```
tds-platform-fe/
│
├── .cursor/                    # cursor项目级配置目录（推荐）
│   ├── rules                   # 提交信息检查
│   └── skills                  # 提交前检查
│
├── .husky/                    # Git hooks 配置（推荐）
│   ├── commit-msg             # 提交信息检查
│   └── pre-commit             # 提交前检查
│
├── public/                    # 静态资源目录（强制）
│   ├── index.html             # HTML 入口文件（强制）
│   └── logo.ico               # 网站图标（可选）
│
├── scripts/                   # 构建脚本（强制）
│   └── branch-version-plugin.js  # 分支版本插件
│
├── src/                       # 源代码目录（强制）
│   ├── api/或server/           # API 接口定义目录（强制）
│   │
│   ├── assets/               # 静态资源（强制）
│   │   ├── icons/            # SVG 图标目录（推荐）
│   │   │   ├── fill/         # 填充图标（推荐）
│   │   │   ├── svg/          # 普通 SVG 图标（推荐）
│   │   │   └── xxx/          # 其他填充图标（可选）
│   │   └── images/            # 图片资源（强制）
│   │       ├── 404/          # 404 页面图片（强制）
│   │       ├── common/       # 通用图片（推荐）
│   │       └── xxx/          # 其他图片（可选）
│   │
│   ├── components/           # 全局组件（强制）
│   │   ├── xxx/              # 某组件目录（可选）
│   │   └── index.js          # 全局组件导出入口（可选）
│   │
│   ├── constants/             # 常量定义目录（推荐）
│   │
│   ├── layouts/              # 布局组件（强制）
│   │   └── normal-layout/    # 标准布局（推荐，也可以是其他命名）
│   │       ├── breadcrumb/   # 面包屑导航
│   │       ├── nav-head/     # 顶部导航
│   │       ├── side-bar/     # 侧边栏
│   │       └── index.vue     # 默认布局入口
│   │
│   ├── mixins/               # Vue Mixins目录（强制）
│   │
│   ├── router/               # 路由配置（强制）
│   │   ├── async-routes/     # 异步路由（推荐）
│   │   │   ├── xxx.js        # 按模块划分的路由配置文件
│   │   │   └── index.js      # 路由入口（推荐）
│   │   ├── guards/           # 自定义路由守卫目录（可选）
│   │   ├── index.js          # 路由主文件（强制）
│   │   └── routerEach.js     # 路由守卫钩子（强制）
│   │
│   ├── store/                # Vuex 状态管理（强制）
│   │   ├── modules/          # 状态模块（强制）
│   │   │   ├── xxx.js               # 其他模块（可选）
│   │   │   ├── global.js            # 全局模块（强制）
│   │   │   └── permission.js        # 权限模块（强制）
│   │   ├── getters.js        # 全局 getters（推荐）
│   │   └── index.js          # Store 入口（强制）
│   │
│   ├── styles/               # 全局样式（强制）
│   │   └── index.scss        # 样式入口（强制）
│   │
│   ├── types/                # jsdoc 类型定义（推荐）
│   │   └── xxx.js            # 类型定义子文件
│   │
│   ├── utils/                # 工具函数（强制）
│   │   ├── bus.js                    # 事件总线（推荐）
│   │   ├── nprogress.js              # 进度条工具（强制）
│   │   ├── request.js                 # HTTP 请求封装（强制）
│   │   ├── utils-download.js          # 下载工具（推荐）
│   │   ├── utils-global.js            # 全局工具（推荐）
│   │   ├── utils-object.js            # 对象工具（推荐）
│   │   ├── utils-owner.js             # 所有者工具（推荐）
│   │   ├── utils-path.js              # 路径工具（推荐）
│   │   ├── utils-route.js             # 路由工具（推荐）
│   │   ├── utils-storage.js           # 存储工具（推荐）
│   │   └── utils-transfer.js          # 转换工具（推荐）
│   │
│   ├── views/                # 页面视图（强制）
│   │   ├── xxx/              # 某视图目录，按实际需求定义子目录和页面
│   │   │   ├── xxx/            # 子页面
│   │   │   └── yyy/            # 子页面
│   │   │
│   │   └── base-page/        # 基础页面（推荐）
│   │       ├── 404/          # 404 错误页（强制）
│   │       ├── iframe/       # iframe 页面（可选）
│   │       ├── login/        # 登录/注册页（可选）
│   │       └── redirect/     # 重定向页（可选）
│   │
│   ├── App.vue               # 根组件（强制）
│   └── main.js               # 应用入口（强制）
│
├── .editorconfig             # 编辑器配置（强制）
├── .env.development          # 开发环境变量（推荐）
├── .env.production           # 生产环境变量（推荐）
├── .eslintignore             # ESLint 忽略配置（推荐）
├── .eslintrc.js              # ESLint 配置（强制）
├── .gitignore                # Git 忽略配置（强制）
├── .npmrc                    # NPM 配置（强制）
├── .prettierrc.js            # Prettier 配置（强制）
├── .stylelintignore          # Stylelint 忽略配置
├── .stylelintrc.js           # Stylelint 配置（强制）
├── babel.config.js           # Babel 配置（强制）
├── commitlint.config.js      # Commitlint 配置（强制）
├── jsconfig.json             # JavaScript 配置（强制）
├── package.json              # 项目依赖配置（强制）
├── README.md                 # 项目说明文档（可选）
├── vue.config.js             # Vue CLI 配置（强制）
└── vue.custom.js             # Vue 自定义配置（强制）
```