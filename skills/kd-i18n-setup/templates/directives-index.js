// 导入当前目录下的所有文件
const files = require.context("./", true, /\.js$/);
const directives = {};
files.keys().forEach((key) => {
  if (key === "./index.js") return;
  directives[key.replace(/(\.\/|\.js)/g, "")] = files(key).default;
});
export default {
  install(Vue) {
    Object.keys(directives).forEach((key) => {
      Vue.directive(key, directives[key]);
    });
  },
};
