#!/usr/bin/env python3
from __future__ import annotations

import argparse
import importlib
import json
import os
import sys
from pathlib import Path

DEFAULT_CONTRACTS_PATH = "/etc/simplelogin-aio/env-enum-contracts.json"
DEFAULT_CODE_PATH = "/code"


def load_contracts() -> dict[str, dict[str, object]]:
    contracts_path = Path(
        os.environ.get("SIMPLELOGIN_ENUM_CONTRACTS_PATH", DEFAULT_CONTRACTS_PATH)
    )
    return json.loads(contracts_path.read_text())


def load_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key] = value
    return values


def get_allowed_values(
    contract: dict[str, object],
    *,
    current_env: bool,
) -> list[str]:
    if current_env:
        container_env_values = contract.get("container_env_values")
        if container_env_values:
            return list(container_env_values)
    return list(contract["runtime_values"])


def validate_values(
    values: dict[str, str],
    contracts: dict[str, dict[str, object]],
    *,
    source_label: str,
    require_write_env: bool,
    current_env: bool,
) -> list[str]:
    errors: list[str] = []

    for name, contract in contracts.items():
        if require_write_env and not contract.get("write_env", False):
            continue
        if name not in values:
            continue

        value = values[name]
        allowed_values = get_allowed_values(contract, current_env=current_env)
        if value not in allowed_values:
            allowed_rendered = ", ".join(allowed_values)
            errors.append(
                f"{source_label}: {name}={value!r} is invalid. Allowed values: {allowed_rendered}."
            )

    return errors


def validate_upstream_import(env_file_values: dict[str, str]) -> list[str]:
    errors: list[str] = []
    original_environ = dict(os.environ)

    try:
        os.environ.update(env_file_values)
        code_path = os.environ.get("SIMPLELOGIN_CODE_PATH", DEFAULT_CODE_PATH)
        if code_path not in sys.path:
            sys.path.insert(0, code_path)
        importlib.import_module("app.config")
    except Exception as exc:  # pragma: no cover - exercised in container runtime
        errors.append(f"rendered env import: upstream config import failed: {exc}")
    finally:
        os.environ.clear()
        os.environ.update(original_environ)

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate SimpleLogin enum-style env values before service startup."
    )
    parser.add_argument(
        "--env-file",
        type=Path,
        help="Rendered dotenv file to validate.",
    )
    parser.add_argument(
        "--validate-current-env",
        action="store_true",
        help="Validate the current process environment as well.",
    )
    parser.add_argument(
        "--import-upstream-config",
        action="store_true",
        help="Import upstream app.config after loading the rendered dotenv values.",
    )
    args = parser.parse_args()

    contracts = load_contracts()
    errors: list[str] = []
    env_file_values: dict[str, str] = {}

    if args.validate_current_env:
        current_env_values = {
            name: os.environ[name] for name in contracts if name in os.environ
        }
        errors.extend(
            validate_values(
                current_env_values,
                contracts,
                source_label="container environment",
                require_write_env=False,
                current_env=True,
            )
        )

    if args.env_file:
        env_file_values = load_env_file(args.env_file)
        errors.extend(
            validate_values(
                env_file_values,
                contracts,
                source_label=f"rendered env {args.env_file}",
                require_write_env=True,
                current_env=False,
            )
        )

    if args.import_upstream_config:
        if not args.env_file:
            parser.error("--import-upstream-config requires --env-file")
        errors.extend(validate_upstream_import(env_file_values))

    if errors:
        print(
            "FATAL: SimpleLogin configuration validation failed. Refusing to start dependent services.",
            file=sys.stderr,
        )
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print("SimpleLogin configuration validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
