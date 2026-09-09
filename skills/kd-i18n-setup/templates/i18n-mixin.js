// i18nMixin 是 @voerkai18n/vue2 的 mixin，用于处理国际化
// 包含 activeLanguage-当前语言计算属性、changeLanguage-切换语言方法、languages-语言列表计算属性
import { i18nMixin as voerkai18nMixin } from "@voerkai18n/vue2";
// const isProd = process.env.NODE_ENV === "production";
// const inQiankun = process.env.VUE_APP_INQIANKUN === "true";
import { inQiankun, isProd } from "/vue.custom.js";
import { rtlLanguages } from "@/constants/i18n.js";

export const i18nMixin = {
  mixins: [voerkai18nMixin()],
  mounted() {
    document.documentElement.setAttribute("dir", this.htmlDirection);
  },
  watch: {
    htmlDirection(dir) {
      document.documentElement.setAttribute("dir", dir);
    },
  },
  provide() {
    return {
      htmlDir: this.htmlDir,
      isRtl: this.isRtl,
    };
  },
  computed: {
    isRtl() {
      const lang = this.activeLanguage || localStorage.getItem("language") || "zh";
      return rtlLanguages.includes(lang);
    },
    htmlDirection() {
      return this.isRtl ? "rtl" : "ltr";
    },
  },
  methods: {
    setLanguage(language) {
      this.changeLanguage(language);
      document.documentElement.setAttribute("dir", this.htmlDirection);
      if (!inQiankun || !isProd) {
        localStorage.setItem("language", language);
      }
    },
    // 适用于el-table-column的width、el-form的label-width的宽度配置
    getI18nWidth(widthConfig) {
      let widths;
      if (typeof widthConfig === "string") {
        widths = widthConfig.split(",").map((val) => {
          return typeof parseInt(val) === "number" && !isNaN(parseInt(val)) ? `${parseInt(val)}px` : val;
        });
      } else if (typeof widthConfig === "object") {
        widths = {};
        for (const [key, val] of Object.entries(widthConfig)) {
          widths[key] = typeof parseInt(val) === "number" && !isNaN(parseInt(val)) ? `${parseInt(val)}px` : val;
        }
      }
      const lang = this.activeLanguage;
      let width;

      if (typeof widths === "object" && !Array.isArray(widths)) {
        width = widths[lang] || widths["zh"] || "auto";
      } else {
        switch (lang) {
          case "zh":
            width = widths[0] || "auto";
            break;
          case "en":
            width = widths[1] || widths[0] || "auto";
            break;
          case "jp":
            width = widths[2] || widths[0] || "auto";
            break;
          default:
            width = widths[0] || "auto";
        }
      }
      return width;
    },
    mValidateChinese(str) {
      return this.mValidateName(str);
    },
  },
};
