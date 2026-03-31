#!/usr/bin/env bash
# notes.sh — Note add and list commands

cmd_note() {
  local name="${1:-}"; [[ -n "$name" ]] || die "Usage: project note \"<project>\" [<phase#> [<step#>]] \"<text>\" [--repo <r>] [--target <t>]"
  require_project "$name"
  shift

  local phase_num="" step_num="" text="" repo="" target=""

  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    phase_num="$1"; shift
    if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
      step_num="$1"; shift
    fi
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)   repo="${2:-}";   shift 2 ;;
      --target) target="${2:-}"; shift 2 ;;
      *)
        if [[ -z "$text" ]]; then
          text="$1"; shift
        else
          die "Unexpected argument '$1'"
        fi
        ;;
    esac
  done

  [[ -n "$text" ]] || die "Note text is required"

  local key="project"
  [[ -n "$phase_num" ]] && key="p${phase_num}"
  [[ -n "$step_num" ]]  && key="p${phase_num}_s${step_num}"
  [[ -n "$repo" ]]      && key+="_r${repo}"
  [[ -n "$target" ]]    && key+="_t${target}"

  local nf; nf=$(notes_file "$name")
  python3 << PYEOF
import json, os, datetime
nf = "$nf"
data = json.load(open(nf)) if os.path.exists(nf) else {}
key = "$key"
text = """$text"""
if key not in data:
    data[key] = []
data[key].append({"text": text, "date": datetime.date.today().isoformat()})
json.dump(data, open(nf, "w"), indent=2)
PYEOF

  local desc="project"
  [[ -n "$phase_num" && -z "$step_num" ]] && desc="Phase $phase_num"
  [[ -n "$step_num" ]] && desc="Step $step_num of Phase $phase_num"
  [[ -n "$repo" ]]   && desc+=" [${repo}]"
  [[ -n "$target" ]] && desc+=" → ${target}"
  echo -e "${GREEN}✓ Note added to $desc${RESET}"
}

cmd_notes() {
  local name="${1:-}"; [[ -n "$name" ]] || die "Usage: project notes \"<project>\""
  require_project "$name"

  local nf; nf=$(notes_file "$name")
  echo -e "\n${BOLD}📝 Notes for $name${RESET}\n"

  python3 - "$nf" <<'PYEOF'
import json, os, sys

nf = sys.argv[1]
data = json.load(open(nf)) if os.path.exists(nf) else {}

if not data:
    print("  (no notes yet)")
    sys.exit(0)

DIM = "\033[2m"
RESET = "\033[0m"
BOLD = "\033[1m"

for key in sorted(data.keys()):
    notes = data[key]
    if not notes:
        continue
    if key == "project":
        label = "Project"
    else:
        parts = key.split("_")
        label_parts = []
        for p in parts:
            if p.startswith("p"): label_parts.append(f"Phase {p[1:]}")
            elif p.startswith("s"): label_parts.append(f"Step {p[1:]}")
            elif p.startswith("r"): label_parts.append(f"[{p[1:]}]")
            elif p.startswith("t"): label_parts.append(f"→ {p[1:]}")
        label = " ".join(label_parts)

    print(f"  {BOLD}{label}{RESET}")
    for note in notes:
        print(f"    {DIM}{note['date']}{RESET}  {note['text']}")
    print()
PYEOF
}
