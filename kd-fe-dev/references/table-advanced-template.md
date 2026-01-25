# 高级筛选表格页面模板

说明：

- 表格页面需要依赖 createTableMixin ，所以应保证项目下存在 /src/mixins/table-mixin.js，如不存在则创建该文件，参考：[模板](./table-mixin-template.md)
- 使用该模板时，应按照最简实现去编写，createTableMixin的queryApi参数可不写，不会报错

```vue
<template>
  <div>
    <kd-page-title :border="false"></kd-page-title>

    <div style="padding: 0 24px 24px">

      <kd-auto-search :form-arr="formArr" @search="autoSearchQuery" @reset="autoSearchReset" @change="autoSearchChange"></kd-auto-search>

      <kd-simple-table ref="simpleTable" :loading="tableLoading" :data="tableData" :paging-attrs="pageConf" :show-paging="false">
        <el-table-column type="selection" reserve-selection></el-table-column>
        <el-table-column type="index" label="序号" width="60px"></el-table-column>
        <kd-column-text label="排序列" prop="appAuthNum" sortable="custom"></kd-column-text>
        <kd-column-text label="展示列" prop="appAuthNum"></kd-column-text>
      </kd-simple-table>
    </div>
  </div>
</template>

<script>
import { createTableMixin } from "@/mixins/table-mixin"

export default {
  name: "TableBasic",
  mixins: [createTableMixin({
    // 查询方法，此处只作示例，缺少该参数不会报错，后期需更换为真实接口
    // queryApi: queryList,  
  })],
  data() {
    return {
      formArr: [
        {
          prop: "name",
          value: "",
          title: "关键词",
          placeholder: "请输入关键词",
          first: true,
        },
      ],
    }
  },
  methods:{
    queryParamsHandle(defaultParams){
      return defaultParams;
    },
    queryResetHandle() {},
    queryResultHandle(res, params) {},
  }
};
</script>

<style scoped lang="scss"></style>
```