<template>
  <svg :style="iconStyle" aria-hidden="true" viewBox="0 0 1024 1024" v-on="$listeners">
    <use class="svg-use" :xlink:href="symbolId" :fill="color" />
  </svg>
</template>

<script>
export default {
  name: "SvgIcon",
  props: {
    prefix: {
      type: String,
      default: "svg",
    },
    name: {
      type: String,
      default: "",
    },
    color: {
      type: String,
      // default: "var(--text-color-secondary)",
      default: "",
    },
    styles: {
      type: Object,
      default: () => {},
    },
    pointer: {
      type: Boolean,
      default: false,
    },
    // 图标尺寸，单位px，如果用逗号分隔，第一个值为宽度，第二个值为高度
    size: {
      type: String,
      default: "16px",
    },
    mt: {
      type: String,
      default: "0",
    },
    mr: {
      type: String,
      default: "0",
    },
    mb: {
      type: String,
      default: "0",
    },
    ml: {
      type: String,
      default: "0",
    },
    block: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    symbolId() {
      return `#icon-${this.prefix}-${this.name}`;
    },
    iconStyle() {
      let width = "",
        height = "";
      if (this.size.indexOf(",") > 0) {
        width = this.size.split(",")[0];
        height = this.size.split(",")[1];
      } else {
        width = height = this.size;
      }
      return {
        width: width.endsWith("px") ? width : `${width}px`,
        height: height.endsWith("px") ? height : `${height}px`,
        marginTop: `${this.mt}px`,
        marginBottom: `${this.mb}px`,
        // 逻辑方向：RTL 下 inline-start/end 会自动对调，无需依赖 isRtl
        marginInlineStart: `${this.ml}px`,
        marginInlineEnd: `${this.mr}px`,
        "vertical-align": "middle",
        cursor: this.pointer ? "pointer" : "inherit",
        display: this.block ? "block" : "inline-block",
        ...this.styles,
      };
    },
  },
};
</script>

<style scoped lang="scss">
.svg-icon {
  overflow: hidden;
  vertical-align: -0.15em;
  fill: currentcolor;
}

.svg-external-icon {
  display: inline-block;
  background-color: currentcolor;
  mask-size: cover !important;
}
</style>
