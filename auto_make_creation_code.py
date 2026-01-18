#!/usr/bin/env python3
import argparse
import re
import subprocess
from pathlib import Path


def strip_0x(s: str) -> str:
    s = s.strip()
    return s[2:] if s.lower().startswith("0x") else s


def is_hex(s: str) -> bool:
    return bool(re.fullmatch(r"[0-9a-fA-F]*", s))


def load_env_lines(path: Path) -> list[str]:
    return path.read_text().splitlines(True)


def upsert_env(lines: list[str], key: str, value: str) -> list[str]:
    pat = re.compile(rf"^\s*{re.escape(key)}\s*=.*$")
    replaced = False
    out: list[str] = []
    for line in lines:
        if pat.match(line):
            nl = "\n" if line.endswith("\n") else ""
            out.append(f"{key}={value}{nl}")
            replaced = True
        else:
            out.append(line)
    if not replaced:
        if out and not out[-1].endswith("\n"):
            out[-1] = out[-1] + "\n"
        out.append(f"{key}={value}\n")
    return out


def read_env_map(path: Path) -> dict[str, str]:
    env: dict[str, str] = {}
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def run(cmd: list[str]) -> subprocess.CompletedProcess:
    # Never raise CalledProcessError; we want to print useful stdout/stderr.
    return subprocess.run(cmd, text=True, capture_output=True)


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Auto pipeline: forge build -> inspect deployedBytecode -> apply jumpoffset_helper.py (fixed offset=24 by default) "
            "-> update .env -> run make_creation_code.py to compute final creation code."
        )
    )
    parser.add_argument(
        "--contract",
        default="src/CashbackAttack.sol:AccrueCashbackAttack",
        help="Contract identifier for forge inspect (default: src/CashbackAttack.sol:AccrueCashbackAttack)",
    )
    parser.add_argument(
        "--env",
        default=".env",
        help="Path to .env file (default: .env)",
    )
    parser.add_argument(
        "--offset",
        type=int,
        default=24,
        help="Jumpdest offset to apply (default: 24)",
    )
    parser.add_argument(
        "--push-size",
        type=int,
        default=2,
        help="Only adjust PUSH of this size (default: 2). Use 0 to adjust all PUSH sizes.",
    )
    parser.add_argument(
        "--via-ir",
        action="store_true",
        default=True,
        help="Run forge build with --via-ir (default: enabled)",
    )
    parser.add_argument(
        "--no-via-ir",
        action="store_false",
        dest="via_ir",
        help="Disable --via-ir for forge build",
    )
    parser.add_argument(
        "--no-build",
        action="store_true",
        help="Skip forge build step",
    )
    parser.add_argument(
        "--write-env",
        action="store_true",
        default=True,
        help="Write updated values back to .env (default: enabled)",
    )
    parser.add_argument(
        "--no-write-env",
        action="store_false",
        dest="write_env",
        help="Do not modify .env; only print outputs",
    )
    parser.add_argument(
        "--out",
        default="cache/final_creation_code.hex",
        help="Output file for final creation code (default: cache/final_creation_code.hex)",
    )
    args = parser.parse_args()

    env_path = Path(args.env)
    if not env_path.exists():
        raise SystemExit(f".env not found: {env_path}")

    if not args.no_build:
        build_cmd = ["forge", "build"]
        if args.via_ir:
            build_cmd.append("--via-ir")
        p = run(build_cmd)
        if p.returncode != 0:
            msg = (p.stderr or "") + ("\n" if p.stderr and p.stdout else "") + (p.stdout or "")
            raise SystemExit(msg.strip() or "forge build failed")

    # Inspect deployed bytecode
    p = run(["forge", "inspect", args.contract, "deployedBytecode"])
    if p.returncode != 0:
        msg = (p.stderr or "") + ("\n" if p.stderr and p.stdout else "") + (p.stdout or "")
        raise SystemExit(msg.strip() or "forge inspect failed")
    deployed = p.stdout.strip()
    if not deployed.lower().startswith("0x"):
        raise SystemExit(f"Unexpected forge inspect output (expected 0x...): {deployed[:80]}")

    # Apply jump offset adjustment
    helper_cmd = ["python3", "jumpoffset_helper.py", "adjust", deployed, str(args.offset)]
    if args.push_size and args.push_size > 0:
        helper_cmd.append(str(args.push_size))
    p = run(helper_cmd)
    if p.returncode != 0:
        msg = (p.stderr or "") + ("\n" if p.stderr and p.stdout else "") + (p.stdout or "")
        raise SystemExit(msg.strip() or "jumpoffset_helper.py failed")
    adjusted = p.stdout.strip()
    if not adjusted.lower().startswith("0x"):
        raise SystemExit(f"Unexpected jumpoffset_helper.py output (expected 0x...): {adjusted[:80]}")

    adjusted_attack_hex = strip_0x(adjusted)
    if not is_hex(adjusted_attack_hex) or len(adjusted_attack_hex) % 2 != 0:
        raise SystemExit("Adjusted bytecode is not valid even-length hex")

    # Load PREFIX from env
    env_map = read_env_map(env_path)
    prefix = env_map.get("PREFIX")
    if not prefix:
        raise SystemExit("Missing PREFIX in .env")
    prefix_hex = strip_0x(prefix)
    if not is_hex(prefix_hex) or len(prefix_hex) % 2 != 0:
        raise SystemExit("PREFIX is not valid even-length hex")

    adjusted_final = "0x" + prefix_hex + adjusted_attack_hex

    # Update .env (optional)
    if args.write_env:
        lines = load_env_lines(env_path)
        # Keep the existing style: ADJUSTED_ATTACK_BYTECODE is stored without 0x
        lines = upsert_env(lines, "ADJUSTED_ATTACK_BYTECODE", adjusted_attack_hex)
        lines = upsert_env(lines, "ADJUSTED_FINAL_BYTECODE", adjusted_final)
        env_path.write_text("".join(lines))

    # Run make_creation_code.py (it reads .env)
    p = run(["python3", "make_creation_code.py", "--env", str(env_path), "--out", args.out])
    if p.returncode != 0:
        msg = (p.stderr or "") + ("\n" if p.stderr and p.stdout else "") + (p.stdout or "")
        raise SystemExit(msg.strip() or "make_creation_code.py failed")

    creation_path = Path(args.out)
    creation = creation_path.read_text().strip()
    if not creation.lower().startswith("0x"):
        raise SystemExit("Final creation code output is not 0x-prefixed")

    if args.write_env:
        lines = load_env_lines(env_path)
        lines = upsert_env(lines, "FINAL_CREATION_CODE", creation)
        env_path.write_text("".join(lines))

    runtime_len = (len(prefix_hex) + len(adjusted_attack_hex)) // 2
    print("contract             =", args.contract)
    print("offset               =", args.offset)
    print("push_size            =", args.push_size)
    print("runtime_len_bytes     =", runtime_len)
    print("ADJUSTED_ATTACK_BYTECODE (no 0x) len(bytes)=", len(adjusted_attack_hex) // 2)
    print("wrote_creation_file   =", creation_path)
    if not args.write_env:
        print("ADJUSTED_FINAL_BYTECODE=", adjusted_final)
        print("FINAL_CREATION_CODE   =", creation)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
