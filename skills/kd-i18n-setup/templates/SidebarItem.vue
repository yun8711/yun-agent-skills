<script>
export default {
  name: "SidebarItem",
  inject: ["activeMenu", "isRtl"],
  props: {
    // 接收父组件传递的全部路径信息
    routeInfo: {
      type: Object,
      required: true,
    },
    // 菜单层级，因为第1级有icon，第1、2级无缩进，第3级有缩进
    level: {
      type: Number,
      default: 1,
    },
  },
  computed: {
    hasChild() {
      const subMenu = this.routeInfo?.children?.filter((x) => !x?.meta?.hidden) ?? [];
      return subMenu.length !== 0;
    },
    hasIcon() {
      return this.routeInfo?.meta?.icon;
    },
    // 当前激活的路径
    activeMenu2() {
      return this.activeMenu();
    },
  },
  render() {
    let element;
    if (!this.routeInfo.meta.hidden) {
      const iconEl =
        this.level === 1 ? (
          <svg-icon
            name={this.routeInfo.meta.icon}
            color={this.routeInfo.path === this.activeMenu2 ? "var(--primary-color)" : "#909399"}
          ></svg-icon>
        ) : null;
      if (!this.hasChild) {
        element = (
          <el-menu-item
            class={["level-item-" + this.level, this.routeInfo.path === this.activeMenu2 ? "bg" : ""]}
            index={this.routeInfo.path}
            style={{ "min-width": "100%" }}
          >
            {iconEl}
            <span
              slot="title"
              style={{ "margin-left": this.isRtl ? "0" : "8px", "margin-right": this.isRtl ? "8px" : "0" }}
            >
              {this.t(this.routeInfo.meta.title)}
            </span>
          </el-menu-item>
        );
      } else {
        element = (
          <el-submenu index={this.routeInfo.path} popper-append-to-body class={["level-item-" + this.level]}>
            <template slot="title">
              {iconEl}
              <span style={{ marginLeft: this.hasIcon ? "8px" : "24px", marginRight: this.isRtl ? "8px" : "0" }}>
                {this.t(this.routeInfo.meta.title)}
              </span>
            </template>
            {this.routeInfo.children.map((subItem) => {
              return <sidebar-item key={subItem.path} route-info={subItem} level={this.level + 1}></sidebar-item>;
            })}
          </el-submenu>
        );
      }
    }
    return element;
  },
};
</script>

<style scoped lang="scss">
.bg {
  background-color: var(--submenu-hover);
}
</style>
