-- =============================================================================
-- personal-ledger 数据库 Schema 定义 (v2.2 - 行业标准版)
--
-- 这个文件是整个数据库结构的**权威来源**。
-- 您可以直接在这里查看、修改表结构、字段和注释，然后同步更新 scripts/db.py。
-- 推荐使用 DB Browser for SQLite 或 TablePlus 等工具打开 ledger.db 进行可视化管理。
--
-- 设计原则（按您的要求）：
--   - 结构化 + 规范化（外键、索引、审计字段）
--   - 保持简单但便于未来开发和维护
--   - 别称（aliases）简化为 accounts 表的一个 JSON 字段
--   - 转账采用行业标准：一条记录 (type='transfer') + from_account_id + to_account_id
--   - 每个字段都加上必要注释
--   - SQL 标准写法，易于扩展
-- =============================================================================

-- 1. 账户类别 (Account Types)
CREATE TABLE IF NOT EXISTS account_types (
    id           INTEGER PRIMARY KEY,
    name         TEXT NOT NULL UNIQUE,           -- 如: 现金、借记卡、信用卡、储值卡、贷款账户
    description  TEXT,
    icon         TEXT,                            -- 可选图标（如 💵、💳、🏦）
    created_at   TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at   TEXT DEFAULT CURRENT_TIMESTAMP
);

-- 2. 具体账户 (Accounts) - 核心表
CREATE TABLE IF NOT EXISTS accounts (
    id              INTEGER PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE,                 -- 正式名称全局唯一，禁止重复开户
    aliases         TEXT,                             -- 别称，JSON格式数组（如 ["招行卡","CC","信用卡"]）
    type_id         INTEGER NOT NULL,
    current_balance REAL DEFAULT 0.0,                 -- 当前余额（收入增加，支出/转出减少）
    currency        TEXT DEFAULT 'CNY',
    credit_limit    REAL DEFAULT 0.0,                 -- 信用卡额度
    is_active       INTEGER DEFAULT 1,                -- 0=已停用, 1=正常使用
    notes           TEXT,
    created_at      TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at      TEXT DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (type_id) REFERENCES account_types(id)
);

-- 3. 交易类别 (Categories)
CREATE TABLE IF NOT EXISTS categories (
    id             INTEGER PRIMARY KEY,
    name           TEXT NOT NULL UNIQUE,
    type           TEXT NOT NULL CHECK(type IN ('income', 'expense')),
    parent_id      INTEGER,
    default_budget REAL DEFAULT 0,
    created_at     TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at     TEXT DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (parent_id) REFERENCES categories(id)
);

-- 4. 交易记录 (Transactions) - 核心业务表
--    转账处理标准：type = 'transfer' 时使用 from_account_id 和 to_account_id，一条记录完成
CREATE TABLE IF NOT EXISTS transactions (
    id                  INTEGER PRIMARY KEY,
    date                TEXT NOT NULL,                     -- 交易日期 (YYYY-MM-DD)
    amount              REAL NOT NULL CHECK(amount > 0),
    type                TEXT NOT NULL CHECK(type IN ('income', 'expense', 'transfer')),
    account_id          INTEGER NOT NULL,                  -- 主账户：转出账户（for transfer/expense）或转入账户（for income）
    from_account_id     INTEGER,                           -- 转账专用：转出账户ID
    to_account_id       INTEGER,                           -- 转账专用：转入账户ID
    category_id         INTEGER,
    description         TEXT,
    notes               TEXT,
    transfer_group_id   TEXT,                              -- 转账组ID（未来扩展用）
    tags                TEXT,                              -- JSON格式标签数组
    created_at          TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at          TEXT DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (account_id)      REFERENCES accounts(id),
    FOREIGN KEY (from_account_id) REFERENCES accounts(id),
    FOREIGN KEY (to_account_id)   REFERENCES accounts(id),
    FOREIGN KEY (category_id)     REFERENCES categories(id)
);

-- 5. 预算表 (Budgets)
CREATE TABLE IF NOT EXISTS budgets (
    id              INTEGER PRIMARY KEY,
    period          TEXT NOT NULL,                   -- 如 '2026-04'（月度）或 '2026'（年度）
    account_id      INTEGER,
    category_id     INTEGER,
    target_amount   REAL NOT NULL,
    current_amount  REAL DEFAULT 0,
    created_at      TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at      TEXT DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(period, account_id, category_id),
    FOREIGN KEY (account_id)  REFERENCES accounts(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- =============================================================================
-- 索引优化
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_from ON transactions(from_account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_to ON transactions(to_account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_accounts_type ON accounts(type_id);

-- =============================================================================
-- 默认数据
-- =============================================================================

-- 默认账户类别
INSERT OR IGNORE INTO account_types (name, description, icon) VALUES
    ('现金', '实体现金或零钱', '💵'),
    ('借记卡', '银行借记卡、储蓄卡', '🏧'),
    ('信用卡', '各类信用卡', '💳'),
    ('微信', '微信支付、零钱、通货', '💬'),
    ('支付宝', '支付宝余额、余额宝', '📱'),
    ('储值卡', '虚拟储值账户，如食堂饭卡、购物卡、会员卡', '💳'),
    ('贷款账户', '房贷、车贷、个人借款等负债账户', '🏦'),
    ('投资账户', '股票、基金、理财产品', '📈'),
    ('其他', '其他未分类账户', '📦');

-- 默认交易类别
INSERT OR IGNORE INTO categories (name, type, parent_id) VALUES
    -- 收入类
    ('工资', 'income', NULL),
    ('奖金', 'income', NULL),
    ('投资收益', 'income', NULL),
    ('退税', 'income', NULL),
    ('借入', 'income', NULL),
    -- 支出类
    ('餐饮', 'expense', NULL),
    ('交通', 'expense', NULL),
    ('购物', 'expense', NULL),
    ('住房', 'expense', NULL),
    ('水电通讯', 'expense', NULL),
    ('娱乐', 'expense', NULL),
    ('医疗', 'expense', NULL),
    ('学习', 'expense', NULL),
    ('借出', 'expense', NULL),
    ('还款', 'expense', NULL),
    ('礼物', 'expense', NULL),
    ('内部转账', 'expense', NULL),     -- 专门用于转账记录
    ('其他支出', 'expense', NULL);

-- =============================================================================
-- 使用说明
-- =============================================================================
-- 1. 转账处理：type='transfer'，同时填写 from_account_id 和 to_account_id
-- 2. 修改本文件后，必须同步更新 scripts/db.py 中的 init_db() 函数
-- 3. 运行 `python scripts/ledger.py init` 重新初始化数据库
-- 4. 生成报告时应过滤 type='transfer'，避免总收入/总支出虚高
-- =============================================================================
