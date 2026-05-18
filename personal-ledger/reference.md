# personal-ledger 参考文档 (v2.3)

## 数据库 Schema

详见 `schema.sql`（这是权威定义文件）。

### 关键设计说明

**转账处理标准（行业主流做法）**：
- 使用 **一条记录**，`type = 'transfer'`
- 同时填写 `from_account_id` 和 `to_account_id`
- `account_id` 通常指向转出账户
- 报告中自动过滤 `transfer` 类型，避免总收入/总支出虚高
- 支持 `description` 中清晰描述（如“从招商银行卡转到微信”）

**账户约束**：
- **`accounts.name` 全局唯一**（DDL `UNIQUE` + 兼容旧库的 `uq_accounts_name`）；禁止重复开户（见 `create_account`）
- **禁止物理删除**：触发器阻止 `DELETE FROM accounts`；停用请用 `deactivate_account`，恢复用 `reactivate_account`
- 首次 `init_db()` 会执行 `scripts/migrations.py`：若存在同名多行，会合并外键到最小 `id` 再删重复行，最后创建唯一索引与触发器

**账户别称**：
- `accounts.aliases` 字段使用 JSON 数组存储（如 `["招行卡", "CC"]`）
- 记账时仅匹配 **`is_active = 1`** 的账户

**默认数据**：
- 账户类别：现金、借记卡、信用卡、微信、支付宝、储值卡、贷款账户、投资账户
- 交易类别：工资、退税、借入、餐饮、礼物、内部转账、还款等

## 可用函数（scripts/ledger.py）

### add_transaction(data) — 主要入库接口
```python
add_transaction({
    "amount": 52.0,
    "type": "expense",  # income | expense | transfer
    "category": "餐饮",
    "description": "午饭",
    "date": "2026-05-18",  # 可选
    "from_account": "微信",      # 支出/转账：转出
    "to_account": "招商银行卡", # 仅转账：转入
    "account_name": "微信",     # 可选别名，与 from_account 二选一惯例见解析逻辑
})
```

### create_account(name, account_type_name, aliases=None, notes="")
- 新建账户；**名称已存在且启用** → 失败；**已存在且停用** → 提示用 `reactivate_account`，勿重复 INSERT

### deactivate_account(name) / reactivate_account(name)
- 软删除 / 恢复；勿使用 SQL `DELETE`

### list_accounts(include_inactive=False)

### monthly_report(month=None) / list_transactions(limit=10, month=None) / init_db()

## 使用建议

**记录转账**：
- “从招商银行卡转账5000元到微信”

**查询**：
- “显示最近10笔记录”
- “生成本月报告”（转账不会计入总收支）

**维护**：
- 运行 `python3 scripts/ledger.py` 会执行 `init_db()`（含类别种子与账户约束升级）
- 数据库文件：`ledger.db`
- 所有数据本地存储，隐私安全
