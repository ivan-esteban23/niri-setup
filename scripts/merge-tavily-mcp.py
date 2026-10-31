#!/usr/bin/env python3
"""Safely add the Tavily MCP server without replacing other servers."""
import json
import os
from pathlib import Path
import sys
import tempfile


def main():
    destination = Path(sys.argv[1])
    key = os.environ.get("TAVILY_API_KEY", "")
    if not key:
        raise ValueError("TAVILY_API_KEY is empty")
    data = json.loads(destination.read_text(encoding="utf-8")) if destination.exists() else {}
    if not isinstance(data, dict) or not isinstance(data.get("mcpServers", {}), dict):
        raise ValueError("existing MCP configuration must contain an object of servers")
    data.setdefault("mcpServers", {})["tavily"] = {
        "command": "npx", "args": ["-y", "tavily-mcp"], "env": {"TAVILY_API_KEY": key}
    }
    destination.parent.mkdir(parents=True, exist_ok=True)
    temp_path = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=destination.parent, delete=False) as output:
            temp_path = Path(output.name)
            json.dump(data, output, indent=2, ensure_ascii=False)
            output.write("\n")
            output.flush()
            os.fchmod(output.fileno(), 0o600)
        os.replace(temp_path, destination)
    finally:
        if temp_path is not None:
            temp_path.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(f"Could not update Tavily MCP configuration: {exc}", file=sys.stderr)
        sys.exit(1)
