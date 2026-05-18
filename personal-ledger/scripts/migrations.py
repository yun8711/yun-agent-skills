"""
账户表约束：名称唯一（库级 UNIQUE）、禁止物理删除（触发器）。
对旧库的升级：先去重合并外键指向，再创建唯一索引与触发器。
"""
from __future__ import annotations

import sqlite3


def migrate_accounts_constraints(conn: sqlite3.Connection) -> None:
    _dedupe_account_names(conn)
    conn.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS uq_accounts_name ON accounts(name)"
    )
    conn.execute("""
        CREATE TRIGGER IF NOT EXISTS accounts_forbid_delete
        BEFORE DELETE ON accounts
        BEGIN
            SELECT RAISE(ABORT,
                'accounts cannot be deleted; deactivate with is_active=0 instead');
        END;
    """)


def _dedupe_account_names(conn: sqlite3.Connection) -> None:
    dup_names = conn.execute(
        """
        SELECT name FROM accounts
        GROUP BY name
        HAVING COUNT(*) > 1
        """
    ).fetchall()
    if not dup_names:
        return

    for (name,) in dup_names:
        rows = conn.execute(
            """
            SELECT id FROM accounts WHERE name = ?
            ORDER BY id ASC
            """,
            (name,),
        ).fetchall()
        keeper_id = rows[0][0]
        for (old_id,) in rows[1:]:
            conn.execute(
                "UPDATE transactions SET account_id = ? WHERE account_id = ?",
                (keeper_id, old_id),
            )
            conn.execute(
                """
                UPDATE transactions SET from_account_id = ?
                WHERE from_account_id = ?
                """,
                (keeper_id, old_id),
            )
            conn.execute(
                """
                UPDATE transactions SET to_account_id = ?
                WHERE to_account_id = ?
                """,
                (keeper_id, old_id),
            )
            conn.execute(
                "UPDATE budgets SET account_id = ? WHERE account_id = ?",
                (keeper_id, old_id),
            )
            conn.execute(
                """
                DELETE FROM accounts WHERE id = ?
                """,
                (old_id,),
            )
