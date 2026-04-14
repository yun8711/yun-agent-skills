---
name: personal-ledger
description: Manages personal income, expense and transfer records using SQLite with industry-standard design. Supports natural language recording (including transfers from A to B as single transfer record), monthly reports (excluding transfers from totals), account balance tracking. Use when user mentions 记账, 记一笔, 转账, 转钱, 从A转到B, 收支, 月报, 报告, 财务总结, ledger, budget. Always read schema.sql, reference.md and scripts/ledger.py first, then use Shell tool to execute functions.
---

# personal-ledger

**个人记账 Skill** — 采用行业标准数据模型，通过自然语言记录收支和转账，支持智能报告和账户管理。

## Quick Start

1. **初始化**：说“初始化我的记账系统”或直接开始记账。
2. **记录普通交易**：
   - “今天午饭花了52元，类别餐饮”
   - “工资到账15000元”
3. **记录转账**（行业标准：一条记录）：
   - “从招商银行卡转账5000元到微信”
   - “从信用卡转10000到储值卡”
4. **查询**：
   - “生成本月报告”
   - “显示最近10笔记录”
   - “我的账户余额情况”

Agent 会自动解析账户名称或别称，正确处理转账，并过滤转账记录避免总收支虚高。

## How-to Guides

### 记录转账（核心功能）
- 使用自然语言描述“从A转到B金额”
- Agent 会创建一条 `type='transfer'` 记录，同时关联转出和转入账户
- 余额自动更新：转出账户减少，转入账户增加
- 报告中自动排除转账记录

### 生成财务报告
- 调用 `monthly_report()`，自动过滤 `transfer` 类型
- 提供汇总、分类明细 + 智能洞察（“本月餐饮占比42%”等）

### 账户管理
- 支持别称匹配（例如“招行卡”可匹配“招商银行卡”）
- 默认包含储值卡、贷款账户等常用类型

## Reference

详见：
- [`schema.sql`](schema.sql) —— 数据库结构权威定义
- [`reference.md`](reference.md) —— 详细 API 和使用说明
- `scripts/ledger.py` —— 核心实现

**转账字段说明**（schema.sql）：
- `type = 'transfer'`
- `from_account_id` + `to_account_id`
- `account_id` 一般为转出方

## Explanation

此 Skill 采用**行业标准转账处理方式**（一条记录同时记录转出和转入），符合 GnuCash、YNAB、Ledger 等专业工具的设计理念。

**为什么这样设计？**
- 结构清晰，易于维护和未来扩展
- 避免总收入/总支出统计失真
- 符合复式记账思想的简化版
- 便于生成准确的账户余额和财务报告

**触发场景**：
- 任何包含“记账”、“转账”、“从...转到...”、“月报”、“报告”、“余额”等关键词的请求。

此 Skill 遵循 Diátaxis 框架，并严格按照 create-skill 最佳实践构建。
