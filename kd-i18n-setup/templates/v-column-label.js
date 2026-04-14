// 在 main.js 或者其他合适的地方注册自定义指令
import Vue from "vue";
import { t } from "@/languages";

Vue.directive("column-label", {
  bind: fun,
  update: fun,
});

function fun(el, binding, vnode) {
  vnode.data.attrs.label = t("操作");
}
