#!/usr/bin/env python3
"""
personal-ledger 数据库核心模块 (v2.2)
采用行业标准转账处理：一条 transfer 记录 + from_account_id + to_account_id
"""
import sqlite3
import json
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional

DB_PATH = Path(__file__).parent.parent / "ledger.db"
DB_PATH.parent.mkdir(parents=True, exist_ok=True)

def get_connection() -> sqlite3.Connection:
    """获取数据库连接"""
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn

def init_db() -> None:
    """初始化数据库表和默认数据（使用 schema.sql 的最新标准结构）"""
    conn = get_connection()
    try:
        conn.executescript("""
            -- 账户类别
            CREATE TABLE IF NOT EXISTS account_types (
                id           INTEGER PRIMARY KEY,
                name         TEXT NOT NULL UNIQUE,
                description  TEXT,
                icon         TEXT,
                created_at   TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at   TEXT DEFAULT CURRENT_TIMESTAMP
            );

            -- 账户主表
            CREATE TABLE IF NOT EXISTS accounts (
                id              INTEGER PRIMARY KEY,
                name            TEXT NOT NULL,
                aliases         TEXT,
                type_id         INTEGER NOT NULL,
                current_balance REAL DEFAULT 0.0,
                currency        TEXT DEFAULT 'CNY',
                credit_limit    REAL DEFAULT 0.0,
                is_active       INTEGER DEFAULT 1,
                notes           TEXT,
                created_at      TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at      TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (type_id) REFERENCES account_types(id)
            );

            -- 交易类别
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

            -- 交易记录 - 核心表（行业标准转账设计：一条记录同时记录 from 和 to）
            CREATE TABLE IF NOT EXISTS transactions (
                id                  INTEGER PRIMARY KEY,
                date                TEXT NOT NULL,
                amount              REAL NOT NULL CHECK(amount > 0),
                type                TEXT NOT NULL CHECK(type IN ('income', 'expense', 'transfer')),
                account_id          INTEGER NOT NULL,
                from_account_id     INTEGER,
                to_account_id       INTEGER,
                category_id         INTEGER,
                description         TEXT,
                notes               TEXT,
                transfer_group_id   TEXT,
                tags                TEXT,
                created_at          TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at          TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (account_id)      REFERENCES accounts(id),
                FOREIGN KEY (from_account_id) REFERENCES accounts(id),
                FOREIGN KEY (to_account_id)   REFERENCES accounts(id),
                FOREIGN KEY (category_id)     REFERENCES categories(id)
            );

            -- 预算表
            CREATE TABLE IF NOT EXISTS budgets (
                id              INTEGER PRIMARY KEY,
                period          TEXT NOT NULL,
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

            -- 索引
            CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
            CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(account_id);
            CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
            CREATE INDEX IF NOT EXISTS idx_accounts_type ON accounts(type_id);
        """)

        # 插入默认数据
        conn.executescript("""
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

            INSERT OR IGNORE INTO categories (name, type, parent_id) VALUES
                ('工资', 'income', NULL),
                ('奖金', 'income', NULL),
                ('投资收益', 'income', NULL),
                ('退税', 'income', NULL),
                ('借入', 'income', NULL),
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
                ('内部转账', 'expense', NULL),
                ('其他支出', 'expense', NULL);
        """)

        conn.commit()
        print(f"✅ 数据库初始化完成: {DB_PATH}")
        print("   已包含标准转账支持（type='transfer' + from/to account）")
        print("   默认账户类别和交易类别已更新")
    except Exception as e:
        print(f"❌ 初始化失败: {e}")
    finally:
        conn.close()

def add_transaction(
    amount: float,
    category: str,
    description: str = "",
    trans_type: str = "expense",
    date: Optional[str] = None,
    account_name: Optional[str] = None,      # 主账户
    from_account: Optional[str] = None,      # 转账专用
    to_account: Optional[str] = None,        # 转账专用
    tags: Optional[List[str]] = None
) -> Dict[str, Any]:
    """添加交易记录，支持行业标准的转账处理"""
    if date is None:
        date = datetime.now().strftime("%Y-%m-%d")
    
    if amount < 0:
        amount = abs(amount)
        if trans_type == "expense":
            trans_type = "expense"

    tags_json = json.dumps(tags) if tags else None

    conn = get_connection()
    try:
        cursor = conn.execute(
            """
            INSERT INTO transactions 
            (date, amount, type, account_id, from_account_id, to_account_id, category_id, description, tags)
            VALUES (?, ?, ?, 
                    (SELECT id FROM accounts WHERE name = ? OR aliases LIKE ? LIMIT 1),
                    (SELECT id FROM accounts WHERE name = ? OR aliases LIKE ? LIMIT 1),
                    (SELECT id FROM accounts WHERE name = ? OR aliases LIKE ? LIMIT 1),
                    (SELECT id FROM categories WHERE name = ? LIMIT 1),
                    ?, ?)
            """,
            (date, amount, trans_type, account_name, f'%{account_name}%',
             from_account, f'%{from_account}%' if from_account else None,
             to_account, f'%{to_account}%' if to_account else None,
             category, description, tags_json)
        )
        conn.commit()
        return {
            "success": True, 
            "id": cursor.lastrowid, 
            "message": f"已记录 {trans_type} {amount}元 - {category}"
        }
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        conn.close()

def get_monthly_report(month: Optional[str] = None) -> Dict[str, Any]:
    """生成月度报告（过滤转账记录）"""
    if month is None:
        month = datetime.now().strftime("%Y-%m")

    conn = get_connection()
    try:
        summary = conn.execute("""
            SELECT 
                type,
                COUNT(*) as count,
                SUM(amount) as total
            FROM transactions 
            WHERE date LIKE ? AND type != 'transfer'
            GROUP BY type
        """, (f"{month}%",)).fetchall()

        by_category = conn.execute("""
            SELECT 
                c.name as category,
                t.type,
                SUM(t.amount) as total,
                COUNT(*) as count
            FROM transactions t
            JOIN categories c ON t.category_id = c.id
            WHERE t.date LIKE ? AND t.type != 'transfer'
            GROUP BY c.name, t.type
            ORDER BY total DESC
        """, (f"{month}%",)).fetchall()

        return {
            "month": month,
            "summary": [dict(row) for row in summary],
            "by_category": [dict(row) for row in by_category],
            "success": True
        }
    finally:
        conn.close()

def list_transactions(limit: int = 20, month: Optional[str] = None) -> List[Dict]:
    """列出最近交易"""
    conn = get_connection()
    try:
        query = "SELECT * FROM transactions ORDER BY date DESC, id DESC LIMIT ?"
        params = [limit]
        if month:
            query = "SELECT * FROM transactions WHERE date LIKE ? ORDER BY date DESC, id DESC LIMIT ?"
            params = [f"{month}%", limit]
        
        rows = conn.execute(query, params).fetchall()
        return [dict(row) for row in rows]
    finally:
        conn.close()

if __name__ == "__main__":
    init_db()
