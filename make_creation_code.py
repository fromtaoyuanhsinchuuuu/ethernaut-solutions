#!/usr/bin/env python3
import argparse
import re
from pathlib import Path


def _strip_0x(s: str) -> str:
    s = s.strip()
    return s[2:] if s.lower().startswith("0x") else s


def _is_hex(s: str) -> bool:
    return bool(re.fullmatch(r"[0-9a-fA-F]*", s))


def load_env(path: Path) -> dict[str, str]:
    env: dict[str, str] = {}
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        env[key] = value
    return env


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Build creation bytecode from PREFIX + ADJUSTED_ATTACK_BYTECODE in .env. "
            "Computes runtime length and generates initcode with correct PUSH2 length."
        )
    )
    parser.add_argument(
        "--env",
        default=".env",
        help="Path to .env file (default: .env)",
    )
    parser.add_argument(
        "--out",
        default="cache/final_creation_code.hex",
        help="Output file to write full creation bytecode (default: cache/final_creation_code.hex)",
    )
    args = parser.parse_args()

    env_path = Path(args.env)
    if not env_path.exists():
        raise SystemExit(f".env not found: {env_path}")

    env = load_env(env_path)

    prefix = env.get("PREFIX")
    if not prefix:
        raise SystemExit("Missing PREFIX in .env")

    attack_bytecode = env.get("ADJUSTED_ATTACK_BYTECODE")
    if not attack_bytecode:
        # tolerate the common typo mentioned in the prompt
        attack_bytecode = env.get("ADJUSTE_ATACK_BYTECODE")
    if not attack_bytecode:
        raise SystemExit("Missing ADJUSTED_ATTACK_BYTECODE (or ADJUSTE_ATACK_BYTECODE) in .env")

    prefix_hex = _strip_0x(prefix)
    attack_hex = _strip_0x(attack_bytecode)

    if len(prefix_hex) % 2 != 0:
        raise SystemExit(f"PREFIX hex length is odd: {len(prefix_hex)}")
    if len(attack_hex) % 2 != 0:
        raise SystemExit(f"ADJUSTED_ATTACK_BYTECODE hex length is odd: {len(attack_hex)}")
    if not _is_hex(prefix_hex):
        raise SystemExit("PREFIX contains non-hex characters")
    if not _is_hex(attack_hex):
        raise SystemExit("ADJUSTED_ATTACK_BYTECODE contains non-hex characters")

    runtime_hex = prefix_hex + attack_hex
    runtime_len_bytes = len(runtime_hex) // 2

    if runtime_len_bytes > 0xFFFF:
        raise SystemExit(f"Runtime too large for PUSH2 length: {runtime_len_bytes} bytes")

    # Matches the minimal initcode you've been using:
    # 0x6080604052348015600e575f5ffd5b5061LLLL8061001c5f395ff3fe
    # where LLLL is the runtime byte length (PUSH2 immediate)
    len_hex = f"{runtime_len_bytes:04x}"
    initcode = "0x6080604052348015600e575f5ffd5b5061" + len_hex + "8061001c5f395ff3fe"

    creation = "0x" + initcode[2:] + runtime_hex

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(creation + "\n")

    print("runtime_len_bytes =", runtime_len_bytes)
    print("runtime_len_hex   = 0x" + len_hex)
    print("initcode          =", initcode)
    print("creation_len_bytes=", (len(creation) - 2) // 2)
    print("wrote             =", out_path)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
