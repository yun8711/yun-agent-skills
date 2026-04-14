// postcss.config.js
module.exports = {
  plugins: {
    // Vue CLI 默认插件（必须保留）
    autoprefixer: {},
    // 集成 RTL 转换插件
    "postcss-rtlcss": {
      // 配置项（企业级推荐配置）
      enabled: true,
      // 自动转换 left/right 为逻辑属性，兼容 RTL
      autoRename: true,
      // 忽略 !important 冲突
      ignoreImportant: true,
      // 直接处理 direction 属性，无需手动加前缀
      processRoot: true,
    },
  },
};
