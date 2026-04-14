# personal-ledger 参考文档 (v2.2)

## 数据库 Schema

详见 `schema.sql`（这是权威定义文件）。

### 关键设计说明

**转账处理标准（行业主流做法）**：
- 使用 **一条记录**，`type = 'transfer'`
- 同时填写 `from_account_id` 和 `to_account_id`
- `account_id` 通常指向转出账户
- 报告中自动过滤 `transfer` 类型，避免总收入/总支出虚高
- 支持 `description` 中清晰描述（如“从招商银行卡转到微信”）

**账户别称**：
- `accounts.aliases` 字段使用 JSON 数组存储（如 `["招行卡", "CC"]`）
- Agent 会尝试通过名称或别称匹配账户

**默认数据**：
- 账户类别：现金、借记卡、信用卡、微信、支付宝、储值卡、贷款账户、投资账户
- 交易类别：工资、退税、借入、餐饮、礼物、内部转账、还款等

## 可用函数（scripts/ledger.py）

### record(...) - 主要接口
```python
record(
    amount: float,
    category: str = "其他",
    description: str = "",
    trans_type: str = "expense",   # income, expense, transfer
    date: Optional[str] = None,
    account_name: Optional[str] = None,   # 主账户
    from_account: Optional[str] = None,   # 转账用
    to_account: Optional[str] = None,     # 转账用
    tags: Optional[List[str]] = None
)
```

**转账示例**：
- `record(5000, "内部转账", "从招商银行卡转到微信", "transfer", from_account="招商银行卡", to_account="微信")`

### 其他函数
- `monthly_report(month=None)` — 生成报告（已过滤转账）
- `show_recent(limit=10, month=None)`
- `init_db()` — 重新初始化数据库

## 使用建议

**记录转账**：
- “从招商银行卡转账5000元到微信”
- “转账 10000 从借记卡到支付宝”

**查询**：
- “显示最近10笔记录”
- “生成本月报告”（转账不会计入总收支）

**维护**：
- 定期运行 `init_db()` 更新默认类别
- 数据库文件：`ledger.db`
- 所有数据本地存储，隐私安全

此设计符合行业标准（GnuCash、YNAB、Ledger 等工具的思路），结构清晰，便于未来扩展。
