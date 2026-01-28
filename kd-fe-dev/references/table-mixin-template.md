# table-mixin模板

配合 kd-simple-table 组件一起使用，极大减少了编写表格页面时的重复代码

使用时必须保证 `/src/mixins/` 目录下存在该mixin，如果缺少则使用以下模板创建 `table-mixin.js` 文件

特点：

- createTableMixin 本身是一个函数可以接收参数，并动态创建 table-mixin
- table-mixin 内包含了绝大多数表格操作，包括数据获取、分页操作、表格筛选、表格搜索等
- 在最简单的情况下，只需在使用table-mixin时指定queryApi即可实现一个表格页面

```javascript
// 表格分页+搜索公共功能

/**
 * 用法示例
 *
 * import { createTableMixin } from "@/mixins/table-mixin-v2";
 * export default {
 *   mixins: [createTableMixin({
 *     queryApi: queryList,
 *     autoQueryOnCreated: false,
 *   })],
 * }
 */

import get from "lodash/get";
import isEmpty from "lodash/isEmpty";
import debounce from "lodash/debounce";

/**
 * 创建表格mixin，合并用户自定义数据
 * @param {Object} options - 配置选项
 * @param {Object} options.debug - 是否开启调试模式，默认false
 * @param {Object} options.queryApi - 查询方法
 * @param {Object} options.isPaging - 是否分页查询，默认true
 * @param {Object} options.recordsField - 赋值给tableData的字段
 * @param {Object} options.totalField - 赋值给pageConf.total的字段
 * @param {Object} options.autoInitQuery - 是否自动初始化查询，默认true
//  * @param {Object} options.autoQueryOnCreated - 是否在created中自动调用queryList查询，默认true
//  * @param {Object} options.autoSearchOnChange - 是否在change时自动触发查询，默认false
 * @param {Object} options.autoSearchDebounceTime - 防抖时间，默认500毫秒
 * @returns {Object} Vue mixin对象
 */
export function createTableMixin(options = {}) {
  const {
    debug = false,
    autoInitQuery = true,
    // autoQueryOnCreated = true,
    // autoSearchOnChange = true,
    autoSearchDebounceTime = 500,
    queryApi = null,
    isPaging = true,
    recordsField = "records",
    totalField = "total",
  } = options;

  const debugLog = (...args) => {
    if (debug) {
      console.log(...args);
    }
  };

  // 创建动态的created钩子
  // 这里要注意，不能使用箭头函数，因为箭头函数没有自己的this，会指向外层作用域的this
  // const createdHandler = autoQueryOnCreated
  //   ? function () {
  //       console.log("tableWithSearchMixin: created", autoQueryOnCreated);
  //       this.queryList(true);
  //     }
  //   : undefined;

  // 返回vue mixin对象
  return {
    data() {
      return {
        // 记录调用mixin的参数，方便在devtools中查看
        mixinOptions: options,
        autoInitQuery: autoInitQuery,
        // 搜索参数
        autoSearchParams: {},

        // 分页配置
        pageConf: {
          pageSize: 10,
          currentPage: 1,
          total: 0,
        },

        // 表格数据相关
        tableData: [],
        tableLoading: false,

        // 表格选中数据
        tableSelectData: [],

        // 表格筛选条件
        filterParams: {},

        // 表格排序参数
        sortParams: {},

        // 防抖函数引用
        debouncedAutoSearchChange: null,

        // 记录autoSearch触发次数
        autoSearchCount: 0,
      };
    },

    computed: {
      selectNum() {
        return this.tableSelectData.length || 0;
      },
    },

    beforeDestroy() {
      // 清理防抖函数
      if (this.debouncedAutoSearchChange) {
        this.debouncedAutoSearchChange.cancel();
      }
    },

    methods: {
      // ===== 自动搜索相关方法 =====
      autoSearchQuery() {
        this.queryList(true);
      },

      autoSearchReset(obj) {
        debugLog("重置搜索框参数", obj);
        this.tableReset && this.tableReset();
      },

      autoSearchChange(obj) {
        debugLog("搜索框参数变化", this.autoSearchCount, obj);
        this._updateAutoSearchParams(obj);
        if (this.autoInitQuery && this.autoSearchCount === 0) {
          this.queryList(true);
        }
        this.autoSearchCount++;
        // 使用防抖版本
        if (!this.debouncedAutoSearchChange) {
          this.debouncedAutoSearchChange = debounce(this.queryList, autoSearchDebounceTime);
          return;
        }
        this.debouncedAutoSearchChange(true);
      },
      // 更新autoSearchParams方法:如果参数值为空，则删除searchParams中的对应key
      _updateAutoSearchParams(obj) {
        Object.keys(obj).forEach((key) => {
          if (obj[key] || !isEmpty(obj[key])) {
            this.autoSearchParams[key] = obj[key];
          } else {
            delete this.autoSearchParams[key];
          }
        });
      },
      // ===== 表格基础方法 =====
      // 表格查询方法
      queryList(isReset = false) {
        debugLog("执行queryList", isReset);
        if (this.tableLoading) return;
        // 重置分页数据
        if (isReset) {
          this.pageConf.currentPage = 1;
          this.pageConf.total = 0;
          this.tableData = [];
        }
        // 自定义的重置方法
        this.queryResetHandle();
        // 整理默认参数，最小必要参数
        // 如果不是分页查询，则不包含current和size参数
        const defaultParams = {
          ...this.autoSearchParams,
          ...this.filterParams,
        };
        if (isPaging) {
          defaultParams.current = this.pageConf.currentPage;
          defaultParams.size = this.pageConf.pageSize;
        }
        // 调用组件内的自定义参数处理方法，生成查询参数
        const queryParams = this.queryParamsHandle(defaultParams);
        debugLog("queryList queryParams", queryParams);
        if (queryParams === false) return;
        // 考虑到多参数情况，转换为数组
        const params = Array.isArray(queryParams) ? queryParams : [queryParams];

        // 触发查询
        this.tableLoading = true;
        // 调用查询方法
        // 根据查询参数的类型，展开参数
        // console.log("queryList params", params);
        queryApi(...params)
          .then((res) => {
            this.tableData = res?.[recordsField] || [];
            this.pageConf.total = res?.[totalField] || 0;
            this.queryResultHandle(res, params);
            this.queryPagingHandle();
          })
          .finally(() => {
            this.tableLoading = false;
            // this.openAutoSearchOnChange();
            // if (!this.debouncedAutoSearchChange) {
            //   this.debouncedAutoSearchChange = debounce(this.queryList, autoSearchDebounceTime);
            // }
          });
      },

      queryResetHandle() {},

      /**
       * 参数处理钩子函数
       * 1、为查询方法生成请求参数，考虑到多参数的场景，应该返回一个数组
       * 2、如果返回false，则不进行查询，相当于参数校验方法
       * @param {object} defaultParams - 默认查询参数
       * @returns {array | boolean} - 如果返回false，则不进行查询，如果返回数组，则直接作为查询参数
       */
      queryParamsHandle(defaultParams) {
        return [defaultParams];
      },
      /**
       * 查询结果返回后的额外处理方法
       * 用于在查询结果返回后，对查询结果进行额外处理，
       * @param {object|array} res - 查询结果
       * @param {object|array} params - 查询参数
       */
      queryResultHandle(res, params) {},

      /**
       * 表格分页变化时触发查询
       * @param {object} obj - 分页参数
       * @param {number} obj.currentPage - 当前页码
       * @param {number} obj.pageSize - 每页条数
       */
      tablePageChange(obj) {
        Object.assign(this.pageConf, obj);
        this.queryList();
      },
      /**
       * 表格筛选变化时触发查询
       * @param {object} filters - 筛选参数
       * @param {string} filters.key - 筛选条件
       * @param {any[]} filters.value - 筛选值
       */
      tableFilterChange(filters) {
        Object.keys(filters).forEach((key) => {
          this.filterParams[key] = filters[key];
        });
        this.queryList(true);
      },

      /**
       * 表格排序变化时触发查询，此处只是示例，具体实现需要在组件中实现
       * @param {object} obj - 排序参数
       * @param {string} obj.column - 排序列
       * @param {string} obj.prop - 排序字段
       * @param {string} obj.order - 排序方向
       */
      tableSortChange({ column, prop, order }) {
        if (order) {
          console.log("tableSortChange", prop, order);
        } else {
          console.log("tableSortChange", prop, order);
        }
      },

      /**
       * 表格多选变化时触发查询
       * @param {any[]} selection - 选中数据
       * @param {object} selection.row - 选中行数据
       * @param {object} selection.column - 选中列数据
       * @param {object} selection.rowIndex - 选中行索引
       * @param {object} selection.columnIndex - 选中列索引
       */
      tableSelectionChange(selection) {
        this.tableSelectData = selection;
      },

      /**
       * 表格重置方法
       * 用于重置表格的筛选、排序、多选等状态，一般在搜索框重置时调用
       * @param {string[]|'all'} arr - 要重置的状态，['selection', 'sort', 'filter']
       */
      tableReset(arr = "all") {
        if (!this.$refs.simpleTable) return;
        const array = arr === "all" ? ["selection", "sort", "filter"] : arr;

        if (array.includes("selection")) {
          this.$refs.simpleTable.$refs.kdSimpleTable?.clearSelection();
          this.tableSelectData = [];
        }

        if (array.includes("sort")) {
          this.$refs.simpleTable.$refs.kdSimpleTable?.clearSort();
          this.sortParams = {};
        }

        if (array.includes("filter")) {
          this.$refs.simpleTable.$refs.kdSimpleTable?.clearFilter();
          this.filterParams = {};
        }
      },

      // ===== 工具方法 =====
      emptyFormatter(value) {
        return value || "-";
      },
      /**
       * 查询后处理方法
       * 检查查询结果是否为空，如果为空，则查询上一页
       * 如果查询结果不为空，则不进行处理
       */
      queryPagingHandle() {
        if (this.pageConf.currentPage !== 1 && this.tableData.length === 0) {
          // 根据总条数和每页条数计算总页数，如果总页数为0，则总页数为1
          const totalPage = Math.ceil(this.pageConf.total / this.pageConf.pageSize) || 1;
          // 获取最后一页的页码数
          this.pageConf.currentPage = Math.max(totalPage, 1);
          this.queryList();
        }
      },

      /**
       * 删除后处理方法
       * 用于处理删除后的分页信息，如果删除的条数大于当前页的条数，则查询上一页
       * @param {number} delNum - 删除条数
       */
      delPagingHandle(delNum) {
        const curPageLength = this.tableData.length;
        if (delNum >= curPageLength) {
          this.pageConf.currentPage = Math.max(this.pageConf.currentPage - 1, 1);
        }
      },

      // ===== 批量操作相关 =====
      getBatchNumber(attrPath, attrValue = false) {
        let length = 0;
        if (!attrPath) {
          length = this.tableSelectData.length;
        } else {
          if (!this.tableSelectData.length) {
            length = 0;
          } else {
            length = this.tableSelectData.filter((item) => {
              if (Array.isArray(attrValue)) {
                return attrValue.includes(get(item, attrPath));
              } else {
                return get(item, attrPath) === attrValue;
              }
            }).length;
          }
        }
        return length;
      },

      getBatchDisabled(attrPath, attrValue = false) {
        return this.getBatchNumber(attrPath, attrValue) === 0;
      },

      getBatchText(attrPath, attrValue = false) {
        const num = this.getBatchNumber(attrPath, attrValue);
        return num > 0 ? `(${num})` : "";
      },
    },
  };
}

```
