#!/usr/bin/env bash
# migrate.sh — Migrate existing projects to new notes format (add IDs)

cmd_migrate() {
  local name="${1:-}"

  if [[ "$name" == "--all" ]]; then
    _migrate_all
    return
  fi

  [[ -n "$name" ]] || die "Usage: project migrate \"<project>\" | --all"
  require_project "$name"
  _migrate_one "$name"
}

_migrate_one() {
  local name="$1"
  local nf; nf=$(notes_file "$name")

  if [[ ! -f "$nf" ]]; then
    echo -e "${DIM}$name: no notes file, skipping${RESET}"
    return
  fi

  python3 -c "
$NOTES_PYTHON_PREAMBLE

nf = '$nf'
data = json.load(open(nf)) if os.path.exists(nf) else {}

# Count notes needing migration
count = 0
for key, notes in data.items():
    if key.startswith('_') or not isinstance(notes, list):
        continue
    for note in notes:
        if 'id' not in note:
            count += 1

if count == 0:
    print('$name: already up to date')
else:
    # load_notes does the migration
    load_notes(nf)
    keys = sum(1 for k, v in data.items() if not k.startswith('_') and isinstance(v, list) and v)
    print(f'$name: migrated {count} note(s) across {keys} key(s)')
"
}

_migrate_all() {
  [[ -d "$PROJECTS_DIR" ]] || { echo "No projects directory found."; return; }

  local count=0
  while IFS= read -r -d '' d; do
    local p; p="$(basename "$d")"
    _migrate_one "$p"
    count=$((count + 1))
  done < <(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  echo -e "\n${GREEN}✓ Checked $count project(s)${RESET}"
}
