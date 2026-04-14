#!/usr/bin/env python3
"""
personal-ledger API 层 (最终修复版)
- 干净的数据库操作接口
- AI 负责自然语言解析
- 用户确认后调用 add_transaction(data: dict)
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
    """初始化数据库"""
    conn = get_connection()
    try:
        schema_path = Path(__file__).parent.parent / "schema.sql"
        if schema_path.exists():
            conn.executescript(schema_path.read_text())
        conn.commit()
        print(f"✅ 数据库初始化完成: {DB_PATH}")
    except Exception as e:
        print(f"❌ 初始化失败: {e}")
    finally:
        conn.close()


def get_account_id(account_name: Optional[str]) -> Optional[int]:
    """根据名称或别称查找账户ID"""
    if not account_name:
        return None
    conn = get_connection()
    try:
        row = conn.execute("""
            SELECT id FROM accounts 
            WHERE name = ? OR aliases LIKE ? 
            LIMIT 1
        """, (account_name, f"%{account_name}%")).fetchone()
        return row["id"] if row else None
    finally:
        conn.close()


def add_transaction(data: Dict[str, Any]) -> Dict[str, Any]:
    """核心入库接口 - 接收结构化字典"""
    if not isinstance(data, dict):
        return {"success": False, "error": "data 必须是字典"}

    amount = data.get("amount")
    if amount is None:
        return {"success": False, "error": "缺少 amount 字段"}

    trans_type = data.get("type", "expense")
    from_account = data.get("from_account") or data.get("account_name")
    to_account = data.get("to_account")
    category = data.get("category", "其他")
    description = data.get("description", "")
    date = data.get("date", datetime.now().strftime("%Y-%m-%d"))

    from_id = get_account_id(from_account)
    to_id = get_account_id(to_account)

    if trans_type in ("expense", "transfer") and not from_id:
        return {"success": False, "error": f"找不到转出账户: {from_account}"}
    if trans_type == "transfer" and not to_id:
        return {"success": False, "error": f"找不到转入账户: {to_account}"}

    conn = get_connection()
    try:
        cursor = conn.execute(
            """
            INSERT INTO transactions 
            (date, amount, type, account_id, from_account_id, to_account_id, category_id, description)
            VALUES (?, ?, ?, ?, ?, ?, 
                   (SELECT id FROM categories WHERE name = ? LIMIT 1), ?)
            """,
            (date, float(amount), trans_type, from_id or to_id, from_id, to_id, category, description)
        )
        conn.commit()
        return {
            "success": True,
            "id": cursor.lastrowid,
            "message": f"成功记录 {trans_type} {amount} 元 - {category}"
        }
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        conn.close()


def monthly_report(month: Optional[str] = None) -> Dict[str, Any]:
    """生成月度报告（过滤转账）"""
    if month is None:
        month = datetime.now().strftime("%Y-%m")

    conn = get_connection()
    try:
        summary = conn.execute("""
            SELECT type, COUNT(*) as count, SUM(amount) as total
            FROM transactions 
            WHERE date LIKE ? AND type != 'transfer'
            GROUP BY type
        """, (f"{month}%",)).fetchall()

        by_category = conn.execute("""
            SELECT 
                COALESCE(c.name, '未分类') as category,
                t.type,
                SUM(t.amount) as total,
                COUNT(*) as count
            FROM transactions t
            LEFT JOIN categories c ON t.category_id = c.id
            WHERE t.date LIKE ? AND t.type != 'transfer'
            GROUP BY COALESCE(c.name, '未分类'), t.type
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


def list_transactions(limit: int = 10, month: Optional[str] = None) -> List[Dict]:
    """查询最近交易"""
    conn = get_connection()
    try:
        if month:
            rows = conn.execute(
                "SELECT * FROM transactions WHERE date LIKE ? ORDER BY date DESC, id DESC LIMIT ?",
                (f"{month}%", limit)
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT * FROM transactions ORDER BY date DESC, id DESC LIMIT ?",
                (limit,)
            ).fetchall()
        return [dict(row) for row in rows]
    finally:
        conn.close()


def main():
    print("personal-ledger Skill API (最终修复版)")
    print("AI 负责解析，用户确认后调用 add_transaction(data)")
    init_db()


if __name__ == "__main__":
    main()
