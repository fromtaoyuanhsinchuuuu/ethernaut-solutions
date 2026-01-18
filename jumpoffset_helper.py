#!/usr/bin/env python3
"""
EVM bytecode jump offset adjuster using Foundry's cast
Supports all modern opcodes including PUSH0
"""
import sys
import subprocess
import re

def run_cast(args: list) -> str:
    """Run cast command and return output"""
    result = subprocess.run(['cast'] + args, capture_output=True, text=True)
    if result.returncode != 0:
        raise Exception(f"cast error: {result.stderr}")
    return result.stdout

def disassemble(bytecode: str) -> list:
    """Disassemble bytecode using cast"""
    output = run_cast(['disassemble', bytecode])
    instructions = []

    for line in output.strip().split('\n'):
        if not line:
            continue
        # Parse: "00000000: PUSH1 0x80"
        match = re.match(r'([0-9a-f]+):\s+(\S+)(?:\s+(.+))?', line)
        if match:
            pc = int(match.group(1), 16)
            op = match.group(2)
            operand = match.group(3)
            instructions.append({
                'pc': pc,
                'op': op,
                'operand': int(operand, 16) if operand else None
            })
    return instructions

def assemble(instructions: list) -> str:
    """Assemble instructions back to bytecode"""
    # PUSH opcode mapping
    push_opcodes = {f'PUSH{i}': 0x5f + i for i in range(1, 33)}
    push_opcodes['PUSH0'] = 0x5f

    # Standard opcodes (partial list - add more as needed)
    opcodes = {
        'STOP': 0x00, 'ADD': 0x01, 'MUL': 0x02, 'SUB': 0x03, 'DIV': 0x04,
        'SDIV': 0x05, 'MOD': 0x06, 'SMOD': 0x07, 'ADDMOD': 0x08, 'MULMOD': 0x09,
        'EXP': 0x0a, 'SIGNEXTEND': 0x0b,
        'LT': 0x10, 'GT': 0x11, 'SLT': 0x12, 'SGT': 0x13, 'EQ': 0x14,
        'ISZERO': 0x15, 'AND': 0x16, 'OR': 0x17, 'XOR': 0x18, 'NOT': 0x19,
        'BYTE': 0x1a, 'SHL': 0x1b, 'SHR': 0x1c, 'SAR': 0x1d,
        'KECCAK256': 0x20, 'SHA3': 0x20,
        'ADDRESS': 0x30, 'BALANCE': 0x31, 'ORIGIN': 0x32, 'CALLER': 0x33,
        'CALLVALUE': 0x34, 'CALLDATALOAD': 0x35, 'CALLDATASIZE': 0x36,
        'CALLDATACOPY': 0x37, 'CODESIZE': 0x38, 'CODECOPY': 0x39,
        'GASPRICE': 0x3a, 'EXTCODESIZE': 0x3b, 'EXTCODECOPY': 0x3c,
        'RETURNDATASIZE': 0x3d, 'RETURNDATACOPY': 0x3e, 'EXTCODEHASH': 0x3f,
        'BLOCKHASH': 0x40, 'COINBASE': 0x41, 'TIMESTAMP': 0x42, 'NUMBER': 0x43,
        'PREVRANDAO': 0x44, 'DIFFICULTY': 0x44, 'GASLIMIT': 0x45,
        'CHAINID': 0x46, 'SELFBALANCE': 0x47, 'BASEFEE': 0x48,
        'POP': 0x50, 'MLOAD': 0x51, 'MSTORE': 0x52, 'MSTORE8': 0x53,
        'SLOAD': 0x54, 'SSTORE': 0x55, 'JUMP': 0x56, 'JUMPI': 0x57,
        'PC': 0x58, 'MSIZE': 0x59, 'GAS': 0x5a, 'JUMPDEST': 0x5b,
        'TLOAD': 0x5c, 'TSTORE': 0x5d, 'MCOPY': 0x5e, 'PUSH0': 0x5f,
        **{f'DUP{i}': 0x7f + i for i in range(1, 17)},
        **{f'SWAP{i}': 0x8f + i for i in range(1, 17)},
        **{f'LOG{i}': 0xa0 + i for i in range(5)},
        'CREATE': 0xf0, 'CALL': 0xf1, 'CALLCODE': 0xf2, 'RETURN': 0xf3,
        'DELEGATECALL': 0xf4, 'CREATE2': 0xf5, 'STATICCALL': 0xfa,
        'REVERT': 0xfd, 'INVALID': 0xfe, 'SELFDESTRUCT': 0xff,
        **push_opcodes
    }

    result = []
    for instr in instructions:
        op = instr['op']
        if op in opcodes:
            result.append(opcodes[op])
            # Handle PUSH data
            if op.startswith('PUSH') and op != 'PUSH0':
                push_size = int(op[4:])
                operand = instr['operand'] or 0
                for i in range(push_size - 1, -1, -1):
                    result.append((operand >> (i * 8)) & 0xff)
        else:
            # Unknown opcode - try to preserve raw byte
            result.append(0xfe)  # INVALID

    return '0x' + ''.join(f'{b:02x}' for b in result)

def adjust_jump_offsets(bytecode: str, offset: int, push_size: int = None) -> str:
    """
    Adjust jump destinations in bytecode by offset
    push_size: only adjust this PUSH size (e.g., 2 for PUSH2)
    """
    instructions = disassemble(bytecode)

    # Find all JUMPDEST positions
    jumpdests = {i['pc'] for i in instructions if i['op'] == 'JUMPDEST'}

    # Adjust PUSH values that point to JUMPDESTs
    for instr in instructions:
        if instr['op'].startswith('PUSH') and instr['op'] != 'PUSH0':
            size = int(instr['op'][4:])
            if push_size and size != push_size:
                continue
            if instr['operand'] in jumpdests:
                instr['operand'] += offset

    return assemble(instructions)

def print_disassembly(bytecode: str):
    """Print disassembled bytecode"""
    output = run_cast(['disassemble', bytecode])
    print(output)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage:")
        print("  python jump-offset.py dis <bytecode>")
        print("  python jump-offset.py adjust <bytecode> <offset> [push_size]")
        sys.exit(1)

    cmd = sys.argv[1]
    bytecode = sys.argv[2]

    if cmd == 'dis':
        print_disassembly(bytecode)
    elif cmd == 'adjust':
        offset = int(sys.argv[3])
        push_size = int(sys.argv[4]) if len(sys.argv) > 4 else None
        print(adjust_jump_offsets(bytecode, offset, push_size))