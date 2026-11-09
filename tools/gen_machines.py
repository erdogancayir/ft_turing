# Helper used to write the json files in machines/ (not part of ft_turing).
# Usage: python3 tools/gen_machines.py [output_dir]

import json, os, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "machines"


def T(read, to, write, action):
    return {"read": read, "to_state": to, "write": write, "action": "RIGHT" if action == "R" else "LEFT"}


def dump(m, filename):
    # one transition per line, like the subject
    lines = ["{"]
    lines.append(f'    "name": {json.dumps(m["name"])},')
    lines.append(f'    "alphabet": {json.dumps(m["alphabet"])},')
    lines.append(f'    "blank": {json.dumps(m["blank"])},')
    lines.append(f'    "states": {json.dumps(m["states"])},')
    lines.append(f'    "initial": {json.dumps(m["initial"])},')
    lines.append(f'    "finals": {json.dumps(m["finals"])},')
    lines.append('    "transitions": {')
    items = [(s, ts) for s, ts in m["transitions"].items()]
    for i, (s, ts) in enumerate(items):
        lines.append(f"        {json.dumps(s)}: [")
        for j, t in enumerate(ts):
            comma = "," if j < len(ts) - 1 else ""
            lines.append(f"            {json.dumps(t)}{comma}")
        lines.append("        ]" + ("," if i < len(items) - 1 else ""))
    lines.append("    }")
    lines.append("}")
    with open(os.path.join(OUT, filename), "w") as f:
        f.write("\n".join(lines) + "\n")
    json.load(open(os.path.join(OUT, filename)))


def restore_and_answer(marks):
    """Common ending: go to the left end, restore marked symbols, write y/n
    after the rightmost character, then HALT."""
    syms = ["0", "1"] + list(marks)
    trans = {}
    for ans in ["y", "n"]:
        go_left = f"answer_{ans}_go_left"
        restore = f"answer_{ans}_restore"
        trans[go_left] = [T(s, go_left, s, "L") for s in syms] + [T(".", restore, ".", "R")]
        trans[restore] = (
            [T(s, restore, s, "R") for s in ["0", "1"]]
            + [T(m, restore, orig, "R") for m, orig in marks.items()]
            + [T(".", "HALT", ans, "R")]
        )
    return trans


# ---------------- 1. unary addition ----------------
dump({
    "name": "unary_add",
    "alphabet": ["1", "+", "=", "."],
    "blank": ".",
    "states": ["scan_first", "scan_second", "check_end", "back", "erase_one", "HALT"],
    "initial": "scan_first",
    "finals": ["HALT"],
    "transitions": {
        "scan_first": [T("1", "scan_first", "1", "R"), T("+", "scan_second", "1", "R")],
        "scan_second": [T("1", "scan_second", "1", "R"), T("=", "check_end", ".", "R")],
        "check_end": [T(".", "back", ".", "L")],
        "back": [T(".", "erase_one", ".", "L")],
        "erase_one": [T("1", "HALT", ".", "R")],
    },
}, "unary_add.json")

# ---------------- 2. palindrome ----------------
pal = {
    "pick": [T("0", "seek_end_0", "A", "R"), T("1", "seek_end_1", "B", "R"),
             T("A", "answer_y_go_left", "A", "L"), T("B", "answer_y_go_left", "B", "L"),
             T(".", "HALT", "y", "R")],
}
for d, mark, other in [("0", "A", "1"), ("1", "B", "0")]:
    pal[f"seek_end_{d}"] = [T("0", f"seek_end_{d}", "0", "R"), T("1", f"seek_end_{d}", "1", "R"),
                            T("A", f"check_{d}", "A", "L"), T("B", f"check_{d}", "B", "L"),
                            T(".", f"check_{d}", ".", "L")]
    pal[f"check_{d}"] = [T(d, "back", mark, "L"), T(other, "answer_n_go_left", other, "L"),
                         T(mark, "answer_y_go_left", mark, "L")]
pal["back"] = [T("0", "back", "0", "L"), T("1", "back", "1", "L"),
               T("A", "pick", "A", "R"), T("B", "pick", "B", "R")]
pal.update(restore_and_answer({"A": "0", "B": "1"}))
dump({
    "name": "palindrome",
    "alphabet": ["0", "1", "A", "B", "y", "n", "."],
    "blank": ".",
    "states": list(pal.keys()) + ["HALT"],
    "initial": "pick",
    "finals": ["HALT"],
    "transitions": pal,
}, "palindrome.json")

# ---------------- 3. 0^n1^n ----------------
z = {
    "start": [T("0", "find_1", "X", "R"), T("Y", "check_rest", "Y", "R"),
              T("1", "answer_n_go_left", "1", "L"), T(".", "HALT", "y", "R")],
    "find_1": [T("0", "find_1", "0", "R"), T("Y", "find_1", "Y", "R"),
               T("1", "back", "Y", "L"), T(".", "answer_n_go_left", ".", "L")],
    "back": [T("0", "back", "0", "L"), T("Y", "back", "Y", "L"), T("X", "start", "X", "R")],
    "check_rest": [T("Y", "check_rest", "Y", "R"), T(".", "answer_y_go_left", ".", "L"),
                   T("0", "answer_n_go_left", "0", "L"), T("1", "answer_n_go_left", "1", "L")],
}
z.update(restore_and_answer({"X": "0", "Y": "1"}))
dump({
    "name": "0n1n",
    "alphabet": ["0", "1", "X", "Y", "y", "n", "."],
    "blank": ".",
    "states": list(z.keys()) + ["HALT"],
    "initial": "start",
    "finals": ["HALT"],
    "transitions": z,
}, "0n1n.json")

# ---------------- 4. 0^2n ----------------
dump({
    "name": "02n",
    "alphabet": ["0", "y", "n", "."],
    "blank": ".",
    "states": ["even", "odd", "HALT"],
    "initial": "even",
    "finals": ["HALT"],
    "transitions": {
        "even": [T("0", "odd", "0", "R"), T(".", "HALT", "y", "R")],
        "odd": [T("0", "even", "0", "R"), T(".", "HALT", "n", "R")],
    },
}, "02n.json")

# ---------------- 5. universal machine for unary_add ----------------
# Tape: <state>[<t1>,<t2>,...,<tn>]<simulated tape>
#   each tuple: <state><read><new state><write><L|R>, '_' = simulated blank
#   simulated head = marked symbol on the simulated tape
SIM_STATES = list("ABCDE")         # usable state names, H = halt
HALT = "H"
ALL_STATES = SIM_STATES + [HALT]
SYMS = ["1", "+", "=", "_"]          # simulated alphabet ('_' = blank)
TAPE = {"1": "1", "+": "+", "=": "=", "_": "."}   # how a symbol looks on the tape
MARK = {"1": "i", "+": "p", "=": "e", "_": "b"}   # symbol under the simulated head
UNMARK = {v: k for k, v in MARK.items()}
DIRS = {"L": "L", "R": "R"}

alphabet = ["."] + ["1", "+", "=", "_"] + list(MARK.values()) + ["[", "]", ",", "L", "R"] + ALL_STATES
tr = {}


def add(state, read, to, write, action):
    tr.setdefault(state, []).append(T(read, to, write, action))


def all_but(excluded):
    return [c for c in alphabet if c not in excluded]


# init: go right to ']' and mark the first cell of the simulated tape
for c in all_but(["]"]):
    add("init", c, "init", c, "R")
add("init", "]", "mark_head", "]", "R")

# mark_head: mark the cell under the simulated head, then go back to the start
for s in SYMS:
    add("mark_head", TAPE[s], "go_start", MARK[s], "L")

# go_start: go left until '[', then step on the state cell
for c in all_but(["["]):
    add("go_start", c, "go_start", c, "L")
add("go_start", "[", "fetch_state", "[", "L")

# fetch_state: read current simulated state
for q in SIM_STATES:
    add("fetch_state", q, f"find_head_{q}", q, "R")
add("fetch_state", HALT, "HALT", HALT, "R")

for q in SIM_STATES:
    # find_head_q: go right to the marked cell, read the symbol under the head
    for c in all_but(list(MARK.values())):
        add(f"find_head_{q}", c, f"find_head_{q}", c, "R")
    for s in SYMS:
        add(f"find_head_{q}", MARK[s], f"to_table_{q}_{s}", MARK[s], "L")
    for s in SYMS:
        # to_table_q_s: go left to '[' then step on the first tuple
        for c in all_but(["["]):
            add(f"to_table_{q}_{s}", c, f"to_table_{q}_{s}", c, "L")
        add(f"to_table_{q}_{s}", "[", f"cmp_state_{q}_{s}", "[", "R")
        # cmp_state_q_s: first char of a tuple
        for c in ALL_STATES:
            if c == q:
                add(f"cmp_state_{q}_{s}", c, f"cmp_read_{q}_{s}", c, "R")
            else:
                add(f"cmp_state_{q}_{s}", c, f"skip4_{q}_{s}", c, "R")
        # cmp_read_q_s: second char of a tuple
        for c in SYMS:
            if c == s:
                add(f"cmp_read_{q}_{s}", c, "get_new_state", c, "R")
            else:
                add(f"cmp_read_{q}_{s}", c, f"skip3_{q}_{s}", c, "R")
        # skipN: move to the next tuple; ']' means no transition -> blocked
        for n in [4, 3, 2, 1]:
            for c in all_but([",", "]", "[", "."]):
                add(f"skip{n}_{q}_{s}", c, f"skip{n - 1}_{q}_{s}", c, "R")
        add(f"skip0_{q}_{s}", ",", f"cmp_state_{q}_{s}", ",", "R")

# matching tuple found: read new state, symbol to write, direction
for nq in ALL_STATES:
    add("get_new_state", nq, f"get_write_{nq}", nq, "R")
    for w in SYMS:
        add(f"get_write_{nq}", w, f"get_dir_{nq}_{w}", w, "R")
        for d in DIRS:
            add(f"get_dir_{nq}_{w}", d, f"save_state_{nq}_{w}_{d}", d, "L")
            # save_state: go left to '[' and write the new state on the state cell
            for c in all_but(["["]):
                add(f"save_state_{nq}_{w}_{d}", c, f"save_state_{nq}_{w}_{d}", c, "L")
            add(f"save_state_{nq}_{w}_{d}", "[", f"write_state_{nq}_{w}_{d}", "[", "L")
            for c in ALL_STATES:
                add(f"write_state_{nq}_{w}_{d}", c, f"apply_{w}_{d}", nq, "R")

# apply_w_d: go to the simulated head, write w, move, mark the new head
for w in SYMS:
    for d in DIRS:
        for c in all_but(list(MARK.values())):
            add(f"apply_{w}_{d}", c, f"apply_{w}_{d}", c, "R")
        for m in MARK.values():
            add(f"apply_{w}_{d}", m, "mark_head", TAPE[w], d)

states = list(tr.keys()) + ["HALT"]
dump({
    "name": "utm_unary_add",
    "alphabet": alphabet,
    "blank": ".",
    "states": states,
    "initial": "init",
    "finals": ["HALT"],
    "transitions": tr,
}, "utm_unary_add.json")
print("utm states:", len(states), "transitions:", sum(len(v) for v in tr.values()))
