#!/usr/bin/env python3
"""Claude Code 対話履歴の収集スクリプト。

~/.claude/ 配下のログ（history.jsonl およびプロジェクト別セッション）を
走査し、ユーザーのプロンプトをJSON形式で標準出力に返す。

Usage:
  python3 collect.py                        # 過去7日、全プロジェクト
  python3 collect.py --days 30              # 過去30日
  python3 collect.py --days 0               # 全期間
  python3 collect.py --project myapp        # プロジェクト名でフィルタ
  python3 collect.py --project myapp --days 30
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

# --- 定数 ---

MAX_TEXT_LEN = 500
MAX_SESSION_FILES = 50
MAX_MESSAGES_PER_FILE = 100

NOISE_COMMANDS = frozenset(["/clear", "/help"])

CREDENTIAL_RULES: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"sk-ant-[A-Za-z0-9\-]{20,}"), "Anthropic API Key"),
    (re.compile(r"sk-[A-Za-z0-9]{20,}"), "OpenAI API Key"),
    (re.compile(r"ghp_[A-Za-z0-9]{36,}"), "GitHub PAT"),
    (re.compile(r"gho_[A-Za-z0-9]{36,}"), "GitHub OAuth Token"),
    (re.compile(r"AIza[A-Za-z0-9\-_]{35}"), "Google API Key"),
    (re.compile(r"xox[bpras]-[A-Za-z0-9\-]{10,}"), "Slack Token"),
    (re.compile(r"-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----"), "Private Key"),
    (re.compile(r"(?i)(bearer\s+)[A-Za-z0-9\-._~+/]+=*"), "Bearer Token"),
    (re.compile(r"(?i)aws[_-]?(access|secret)[_-]?key\S*\s*[:=]\s*\S+"), "AWS Key"),
    (re.compile(r"(?i)(mongodb(\+srv)?|postgres(ql)?|mysql)://\S+:\S+@"), "DB Connection String"),
    (re.compile(r"(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*\S+"), "Credential"),
]

_HOME_STR = str(Path.home())


# --- ユーティリティ ---


def _epoch_ms_to_str(ms: int) -> str:
    try:
        return datetime.fromtimestamp(ms / 1000, tz=timezone.utc).strftime("%Y-%m-%d %H:%M")
    except (OSError, ValueError):
        return "unknown"


def _iso_to_epoch_ms(iso: str) -> int | None:
    try:
        dt = datetime.fromisoformat(iso.replace("Z", "+00:00"))
        return int(dt.timestamp() * 1000)
    except (ValueError, AttributeError):
        return None


def _sanitize(text: str) -> str:
    return text.encode("utf-8", errors="replace").decode("utf-8")


def _redact_home_path(text: str) -> str:
    return text.replace(_HOME_STR, "/Users/<user>")


def _mask(value: str) -> str:
    if len(value) > 16:
        return value[:8] + "***" + value[-4:]
    return value[:4] + "***"


def _detect_credentials(text: str) -> list[dict[str, str]]:
    hits: list[dict[str, str]] = []
    covered: list[tuple[int, int]] = []
    for pattern, label in CREDENTIAL_RULES:
        for m in pattern.finditer(text):
            start, end = m.span()
            if any(s <= start and end <= e for s, e in covered):
                continue
            covered.append((start, end))
            hits.append({"type": label, "masked_value": _mask(m.group())})
    return hits


def _extract_content_text(content) -> str:
    """JSONL セッションの message.content からユーザーテキストを取り出す。"""
    if isinstance(content, str):
        return _sanitize(content.strip())
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if not isinstance(item, dict):
                continue
            if item.get("type") == "tool_result":
                continue
            if item.get("type") == "text":
                t = item.get("text", "")
                if re.match(
                    r"^<(ide_opened_file|ide_selection|local-command-caveat"
                    r"|local-command-stdout|system-reminder)\b",
                    t,
                ):
                    continue
                parts.append(t)
        return _sanitize(" ".join(parts).strip())
    return ""


def _is_path_only(text: str) -> bool:
    if "\n" in text or len(text) >= 300 or " " in text:
        return False
    normalized = text.replace("\\", "/")
    return (
        normalized.startswith(("/", "C:", "D:", "c:", "d:"))
        and len(normalized.split("/")) > 2
    )


# --- コレクター ---


def gather_claude_code(cutoff: int | None, proj_filter: str | None) -> list[dict]:
    """Claude Code の history.jsonl とプロジェクト別セッションからプロンプトを収集する。"""
    base = Path.home() / ".claude"
    msgs: list[dict] = []
    seen: set[str] = set()
    known_sessions: set[str] = set()

    # history.jsonl (CLI)
    hist = base / "history.jsonl"
    if hist.exists():
        for line in hist.read_text(encoding="utf-8", errors="replace").splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            display = row.get("display", "").strip()
            ts = row.get("timestamp")
            project = row.get("project", "")
            sid = row.get("sessionId", "")
            if sid:
                known_sessions.add(sid)
            if not display or any(display.startswith(c) for c in NOISE_COMMANDS):
                continue
            if _is_path_only(display):
                continue
            if cutoff and ts and ts < cutoff:
                continue
            if cutoff and not ts:
                continue
            if proj_filter:
                pname = Path(project).name.lower() if project else ""
                if proj_filter.lower() not in pname:
                    continue
            key = f"{ts}:{display[:80]}"
            if key in seen:
                continue
            seen.add(key)
            msgs.append({
                "text": _redact_home_path(display[:MAX_TEXT_LEN]),
                "timestamp": _epoch_ms_to_str(ts) if ts else "unknown",
                "timestamp_ms": ts or 0,
                "project": Path(project).name if project else "unknown",
            })

    # プロジェクト別セッション (VS Code拡張)
    proj_dir = base / "projects"
    if proj_dir.exists():
        for pdir in proj_dir.iterdir():
            if not pdir.is_dir():
                continue
            dirname = pdir.name
            if proj_filter:
                if proj_filter.lower().replace(" ", "-") not in dirname.lower():
                    continue

            files = sorted(
                (f for f in pdir.glob("*.jsonl") if f.is_file()),
                key=lambda p: p.stat().st_mtime,
                reverse=True,
            )[:MAX_SESSION_FILES]

            for sf in files:
                if sf.stem in known_sessions:
                    continue
                if cutoff:
                    mtime_ms = int(sf.stat().st_mtime * 1000)
                    if mtime_ms < cutoff:
                        continue
                try:
                    count = 0
                    for line in sf.read_text(encoding="utf-8", errors="replace").splitlines():
                        if not line.strip():
                            continue
                        try:
                            entry = json.loads(line)
                        except json.JSONDecodeError:
                            continue
                        if entry.get("type") != "user" or entry.get("isMeta"):
                            continue
                        text = _extract_content_text(entry.get("message", {}).get("content", ""))
                        if not text or any(text.startswith(c) for c in NOISE_COMMANDS):
                            continue
                        ts_iso = entry.get("timestamp", "")
                        ts_ms = _iso_to_epoch_ms(ts_iso) if ts_iso else None
                        if cutoff and not ts_ms:
                            continue
                        if cutoff and ts_ms and ts_ms < cutoff:
                            continue
                        key = f"{ts_ms}:{text[:80]}"
                        if key in seen:
                            continue
                        seen.add(key)
                        cwd = entry.get("cwd", "")
                        msgs.append({
                            "text": _redact_home_path(text[:MAX_TEXT_LEN]),
                            "timestamp": _epoch_ms_to_str(ts_ms) if ts_ms else "unknown",
                            "timestamp_ms": ts_ms or 0,
                            "project": Path(cwd).name if cwd else dirname,
                        })
                        count += 1
                        if count >= MAX_MESSAGES_PER_FILE:
                            break
                except (OSError, UnicodeDecodeError):
                    continue

    return msgs


# --- メイン ---


def _non_negative_int(value: str) -> int:
    n = int(value)
    if n < 0:
        raise argparse.ArgumentTypeError("--days must be >= 0")
    return n


def main() -> None:
    parser = argparse.ArgumentParser(description="Claude Code 対話履歴を収集する")
    parser.add_argument("--days", type=_non_negative_int, default=7, help="過去N日分 (0=全期間, default=7)")
    parser.add_argument("--project", type=str, default=None, help="プロジェクト名フィルタ（部分一致）")
    args = parser.parse_args()

    cutoff: int | None = None
    if args.days > 0:
        dt = datetime.now(tz=timezone.utc) - timedelta(days=args.days)
        cutoff = int(dt.timestamp() * 1000)

    messages = gather_claude_code(cutoff, args.project)

    # シークレット検出
    warnings: list[dict] = []
    for msg in messages:
        for hit in _detect_credentials(msg["text"]):
            warnings.append({
                "project": msg.get("project", "unknown"),
                "timestamp": msg.get("timestamp", "unknown"),
                **hit,
                "prompt_excerpt": _redact_home_path(msg["text"][:80].replace("\n", " ")),
            })

    # プロジェクト別集計
    proj_stats: dict[str, int] = {}
    for msg in messages:
        p = msg.get("project", "unknown")
        proj_stats[p] = proj_stats.get(p, 0) + 1

    # 期間算出
    ts_list = [m["timestamp"] for m in messages if m["timestamp"] != "unknown"]
    period_start = min(ts_list) if ts_list else ""
    period_end = max(ts_list) if ts_list else ""

    output = {
        "summary": {
            "total_messages": len(messages),
            "period_start": period_start,
            "period_end": period_end,
            "filter_days": args.days,
            "filter_project": args.project,
            "collected_at": datetime.now(tz=timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        },
        "messages": messages,
        "secret_warnings": warnings,
        "project_stats": dict(sorted(proj_stats.items(), key=lambda x: -x[1])),
    }

    if sys.platform == "win32":
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    json.dump(output, sys.stdout, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
