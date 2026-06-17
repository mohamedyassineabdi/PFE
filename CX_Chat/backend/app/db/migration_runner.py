from __future__ import annotations

from pathlib import Path

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine


def _split_sql_statements(sql: str) -> list[str]:
    statements: list[str] = []
    buffer: list[str] = []
    index = 0
    in_single_quote = False
    in_double_quote = False
    in_line_comment = False
    in_block_comment = False
    dollar_quote_tag: str | None = None

    while index < len(sql):
        char = sql[index]
        next_char = sql[index + 1] if index + 1 < len(sql) else ""

        if in_line_comment:
            buffer.append(char)
            if char == "\n":
                in_line_comment = False
            index += 1
            continue

        if in_block_comment:
            buffer.append(char)
            if char == "*" and next_char == "/":
                buffer.append(next_char)
                index += 2
                in_block_comment = False
            else:
                index += 1
            continue

        if dollar_quote_tag is not None:
            if sql.startswith(dollar_quote_tag, index):
                buffer.append(dollar_quote_tag)
                index += len(dollar_quote_tag)
                dollar_quote_tag = None
            else:
                buffer.append(char)
                index += 1
            continue

        if in_single_quote:
            buffer.append(char)
            if char == "'" and next_char == "'":
                buffer.append(next_char)
                index += 2
            elif char == "'":
                in_single_quote = False
                index += 1
            else:
                index += 1
            continue

        if in_double_quote:
            buffer.append(char)
            if char == '"' and next_char == '"':
                buffer.append(next_char)
                index += 2
            elif char == '"':
                in_double_quote = False
                index += 1
            else:
                index += 1
            continue

        if char == "-" and next_char == "-":
            buffer.extend((char, next_char))
            index += 2
            in_line_comment = True
            continue

        if char == "/" and next_char == "*":
            buffer.extend((char, next_char))
            index += 2
            in_block_comment = True
            continue

        if char == "'":
            buffer.append(char)
            index += 1
            in_single_quote = True
            continue

        if char == '"':
            buffer.append(char)
            index += 1
            in_double_quote = True
            continue

        if char == "$":
            end_index = sql.find("$", index + 1)
            if end_index != -1:
                tag_body = sql[index + 1 : end_index]
                if tag_body == "" or (
                    (tag_body[0].isalpha() or tag_body[0] == "_")
                    and all(part.isalnum() or part == "_" for part in tag_body)
                ):
                    dollar_quote_tag = sql[index : end_index + 1]
                    buffer.append(dollar_quote_tag)
                    index = end_index + 1
                    continue

        if char == ";":
            statement = "".join(buffer).strip()
            if statement:
                statements.append(statement)
            buffer.clear()
            index += 1
            continue

        buffer.append(char)
        index += 1

    statement = "".join(buffer).strip()
    if statement:
        statements.append(statement)

    return statements


def _is_transaction_boundary(statement: str) -> bool:
    normalized = statement.strip().rstrip(";").upper()
    return normalized in {"BEGIN", "COMMIT", "ROLLBACK"}


async def run_pending_sql_migrations(engine: AsyncEngine) -> None:
    migrations_dir = Path(__file__).resolve().parents[2] / "migrations"
    if not migrations_dir.exists():
        return

    migration_files = sorted(
        path for path in migrations_dir.glob("*.sql") if path.is_file()
    )
    if not migration_files:
        return

    async with engine.begin() as connection:
        await connection.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    version TEXT PRIMARY KEY,
                    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                )
                """
            )
        )

        result = await connection.execute(text("SELECT version FROM schema_migrations"))
        applied = {row[0] for row in result.fetchall()}

        for migration_file in migration_files:
            version = migration_file.name
            if version in applied:
                continue

            sql = migration_file.read_text(encoding="utf-8")
            for statement in _split_sql_statements(sql):
                if _is_transaction_boundary(statement):
                    continue
                await connection.exec_driver_sql(statement)

            await connection.execute(
                text("INSERT INTO schema_migrations (version) VALUES (:version)"),
                {"version": version},
            )
