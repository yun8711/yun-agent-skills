<template>
  <div
    v-show="show"
    class="kd-page-title"
    :class="{ 'border-bottom': border }"
    :style="{ height: height, padding: padding }"
  >
    <div class="left">
      <slot name="left" :data="routeInfo">
        <slot>
          <div class="title" :style="titleStyles">
            {{ title || t(routeTitle) }}
          </div>
        </slot>
        <slot name="extend"></slot>
      </slot>
    </div>
    <div class="right">
      <slot name="right"></slot>
    </div>
  </div>
</template>

<script>
import get from "lodash/get";
export default {
  name: "PageTitle",
  props: {
    show: {
      type: Boolean,
      default: true,
    },
    height: {
      type: String,
      default: "44px",
    },
    padding: {
      type: String,
      default: "0 24px",
    },
    border: {
      type: Boolean,
      default: true,
    },
    title: {
      type: String,
      default: "",
    },
    titleStyles: {
      type: Object,
      default: () => {
        return {};
      },
    },
  },
  data() {
    return {
      routeTitle: "",
      routeInfo: {},
    };
  },
  watch: {
    $route: {
      handler(route) {
        if (!route) return;
        this.routeInfo = route;
        this.routeTitle = get(route, "meta.title") || "";
      },
      immediate: true,
      deep: true,
    },
  },
};
</script>
