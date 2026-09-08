#!@python@/bin/python3
"""Invoke the pinned Blender MCP server without configuring a Codex client."""

import argparse
import asyncio
import json
import os
from pathlib import Path
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


async def run(args, arguments):
    server = StdioServerParameters(command="@server@", env=dict(os.environ))
    async with asyncio.timeout(args.timeout):
        async with stdio_client(server) as (reader, writer):
            async with ClientSession(reader, writer) as session:
                await session.initialize()
                if args.action == "list":
                    result = await session.list_tools()
                else:
                    result = await session.call_tool(args.tool, arguments)
                print(result.model_dump_json(by_alias=True, exclude_none=True))
                return 1 if getattr(result, "isError", False) else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--timeout", type=float, default=120,
                        help="Total timeout in seconds (default: 120)")
    commands = parser.add_subparsers(dest="action", required=True)
    commands.add_parser("list", help="List tools and input schemas")
    call = commands.add_parser("call", help="Call one tool")
    call.add_argument("tool")
    call.add_argument("arguments", nargs="?", help="JSON object (default: {})")
    call.add_argument("--args-file", help="Read JSON from a file, or - for stdin")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    arguments = {}
    if args.action == "call":
        if args.arguments is not None and args.args_file is not None:
            parser.error("use either a JSON argument or --args-file")
        try:
            raw = args.arguments or "{}"
            if args.args_file:
                raw = (sys.stdin.read() if args.args_file == "-"
                       else Path(args.args_file).read_text())
            arguments = json.loads(raw)
            if not isinstance(arguments, dict):
                parser.error("tool arguments must be a JSON object")
        except (OSError, ValueError) as exc:
            parser.error(str(exc))
    return asyncio.run(run(args, arguments))


if __name__ == "__main__":
    sys.exit(main())
