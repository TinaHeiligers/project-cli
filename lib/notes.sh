#!/usr/bin/env bash
# notes.sh — Note commands: add, delete, archive, edit, list

cmd_note() {
  local name="${1:-}"; [[ -n "$name" ]] || die "Usage: project note \"<project>\" [delete|archive|edit] ..."
  require_project "$name"
  shift

  # Dispatch subcommands
  case "${1:-}" in
    delete)  shift; cmd_note_delete "$name" "$@" ;;
    archive) shift; cmd_note_archive "$name" "$@" ;;
    edit)    shift; cmd_note_edit "$name" "$@" ;;
    *)       cmd_note_add "$name" "$@" ;;
  esac
}

cmd_note_add() {
  local name="$1"; shift

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
  python3 -c "
$NOTES_PYTHON_PREAMBLE

nf = '$nf'
data = load_notes(nf)
key = '$key'
text = '''$text'''
if key not in data:
    data[key] = []
nid = next_note_id(data)
data[key].append({'id': nid, 'text': text, 'date': datetime.date.today().isoformat()})
save_notes(nf, data)
print(f'(note #{nid})')
"

  local desc="project"
  [[ -n "$phase_num" && -z "$step_num" ]] && desc="Phase $phase_num"
  [[ -n "$step_num" ]] && desc="Step $step_num of Phase $phase_num"
  [[ -n "$repo" ]]   && desc+=" [${repo}]"
  [[ -n "$target" ]] && desc+=" → ${target}"
  echo -e "${GREEN}✓ Note added to $desc${RESET}"
}

cmd_note_delete() {
  local name="$1"; shift
  local note_id="" before="" all=false
  local phase="" step="" repo="" target=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --before)  before="${2:-}";  shift 2 ;;
      --all)     all=true;         shift ;;
      --phase)   phase="${2:-}";   shift 2 ;;
      --step)    step="${2:-}";    shift 2 ;;
      --repo)    repo="${2:-}";    shift 2 ;;
      --target)  target="${2:-}";  shift 2 ;;
      *)
        if [[ -z "$note_id" && "$1" =~ ^[0-9]+$ ]]; then
          note_id="$1"; shift
        else
          die "Unexpected argument '$1'"
        fi
        ;;
    esac
  done

  [[ -n "$note_id" || -n "$before" || "$all" == "true" ]] || \
    die "Usage: project note delete \"<project>\" <id> | --before <date> | --all [--phase N] [--step N] [--repo r] [--target t]"

  local key; key=$(build_note_key --phase "$phase" --step "$step" --repo "$repo" --target "$target")
  local nf; nf=$(notes_file "$name")

  python3 -c "
$NOTES_PYTHON_PREAMBLE

nf = '$nf'
data = load_notes(nf)
key = '$key'
note_id = '$note_id'
before = '$before'
delete_all = $([[ "$all" == "true" ]] && echo "True" || echo "False")

if key not in data or not data[key]:
    print('No notes found for ' + key)
    exit(0)

original_count = len(data[key])

if delete_all:
    data[key] = []
elif note_id:
    nid = int(note_id)
    data[key] = [n for n in data[key] if n.get('id') != nid]
elif before:
    data[key] = [n for n in data[key] if n['date'] >= before]

deleted = original_count - len(data[key])

# Clean up empty keys
if not data[key]:
    del data[key]

save_notes(nf, data)
print(f'Deleted {deleted} note(s) from {key}')
"
}

cmd_note_archive() {
  local name="$1"; shift
  local note_id="" before=""
  local phase="" step="" repo="" target=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --before)  before="${2:-}";  shift 2 ;;
      --phase)   phase="${2:-}";   shift 2 ;;
      --step)    step="${2:-}";    shift 2 ;;
      --repo)    repo="${2:-}";    shift 2 ;;
      --target)  target="${2:-}";  shift 2 ;;
      *)
        if [[ -z "$note_id" && "$1" =~ ^[0-9]+$ ]]; then
          note_id="$1"; shift
        else
          die "Unexpected argument '$1'"
        fi
        ;;
    esac
  done

  [[ -n "$note_id" || -n "$before" ]] || \
    die "Usage: project note archive \"<project>\" <id> | --before <date> [--phase N] [--step N] [--repo r] [--target t]"

  local key; key=$(build_note_key --phase "$phase" --step "$step" --repo "$repo" --target "$target")
  local nf; nf=$(notes_file "$name")

  python3 -c "
$NOTES_PYTHON_PREAMBLE

nf = '$nf'
data = load_notes(nf)
key = '$key'
note_id = '$note_id'
before = '$before'

if key not in data or not data[key]:
    print('No notes found for ' + key)
    exit(0)

archive = data.setdefault('_archive', {})
archive_key = archive.setdefault(key, [])

to_archive = []
to_keep = []

for n in data[key]:
    match = False
    if note_id and n.get('id') == int(note_id):
        match = True
    elif before and n['date'] < before:
        match = True
    if match:
        to_archive.append(n)
    else:
        to_keep.append(n)

data[key] = to_keep
archive[key] = archive_key + to_archive

if not data[key]:
    del data[key]

save_notes(nf, data)
print(f'Archived {len(to_archive)} note(s) from {key}')
"
}

cmd_note_edit() {
  local name="$1"; shift
  local note_id="${1:-}"
  [[ -n "$note_id" ]] || die "Usage: project note edit \"<project>\" <id> \"<new text>\""
  shift
  local text="${1:-}"
  [[ -n "$text" ]] || die "New text is required"

  local nf; nf=$(notes_file "$name")

  python3 -c "
$NOTES_PYTHON_PREAMBLE

nf = '$nf'
data = load_notes(nf)
nid = int('$note_id')
text = '''$text'''

found = False
for key, notes in data.items():
    if key.startswith('_') or not isinstance(notes, list):
        continue
    for note in notes:
        if note.get('id') == nid:
            note['text'] = text
            note['date'] = datetime.date.today().isoformat()
            found = True
            break
    if found:
        break

if not found:
    print(f'Note #{nid} not found')
    exit(1)

save_notes(nf, data)
print(f'Updated note #{nid}')
"
}

cmd_notes() {
  local name="${1:-}"; [[ -n "$name" ]] || die "Usage: project notes \"<project>\" [--archived]"
  require_project "$name"
  shift || true

  local show_archived=false
  [[ "${1:-}" == "--archived" ]] && show_archived=true

  local nf; nf=$(notes_file "$name")

  if [[ "$show_archived" == "true" ]]; then
    echo -e "\n${BOLD}📝 Archived notes for $name${RESET}\n"
  else
    echo -e "\n${BOLD}📝 Notes for $name${RESET}\n"
  fi

  python3 - "$nf" "$show_archived" <<'PYEOF'
import json, os, sys

NOTES_PYTHON_PREAMBLE_INLINE = True

def load_notes(nf):
    data = json.load(open(nf)) if os.path.exists(nf) else {}
    next_id = data.get("_next_id", 1)
    migrated = False
    for key, notes in data.items():
        if key.startswith("_"):
            continue
        if not isinstance(notes, list):
            continue
        for note in notes:
            if "id" not in note:
                note["id"] = next_id
                next_id += 1
                migrated = True
    data["_next_id"] = next_id
    if migrated:
        json.dump(data, open(nf, "w"), indent=2)
    return data

nf = sys.argv[1]
show_archived = sys.argv[2] == "true"
data = load_notes(nf)

source = data.get("_archive", {}) if show_archived else data

if not any(k for k in source if not k.startswith("_")):
    print("  (no notes)")
    sys.exit(0)

DIM = "\033[2m"
RESET = "\033[0m"
BOLD = "\033[1m"

for key in sorted(source.keys()):
    if key.startswith("_"):
        continue
    notes = source[key]
    if not isinstance(notes, list) or not notes:
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
        nid = note.get('id', '?')
        print(f"    #{nid:<4} {DIM}{note['date']}{RESET}  {note['text']}")
    print()
PYEOF
}
