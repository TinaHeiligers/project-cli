#!/usr/bin/env bash
# list.sh — List and archive projects

cmd_list() {
  [[ -d "$PROJECTS_DIR" ]] || { echo "No projects yet. Run: project new \"My Project\""; return; }

  local show_archived=false
  [[ "${1:-}" == "--archived" ]] && show_archived=true

  local projects=()
  while IFS= read -r -d '' d; do
    projects+=("$(basename "$d")")
  done < <(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  if [[ ${#projects[@]} -eq 0 ]]; then
    echo "No projects yet. Run: project new \"My Project\""
    return
  fi

  if [[ "$show_archived" == "true" ]]; then
    echo -e "\n${BOLD}Archived projects in $PROJECTS_DIR${RESET}"
  else
    echo -e "\n${BOLD}Projects in $PROJECTS_DIR${RESET}"
  fi

  local shown=0
  for p in "${projects[@]}"; do
    local sf; sf=$(status_file "$p")
    local mf; mf=$(meta_file "$p")

    # Check archived status
    local is_archived=false
    if [[ -f "$mf" ]]; then
      is_archived=$(python3 -c "import json; d=json.load(open('$mf')); print('true' if d.get('archived') else 'false')")
    fi

    # Filter based on mode
    if [[ "$show_archived" == "true" && "$is_archived" != "true" ]]; then continue; fi
    if [[ "$show_archived" == "false" && "$is_archived" == "true" ]]; then continue; fi

    local done_count=0
    local repos=""
    if [[ -f "$sf" ]]; then
      done_count=$(python3 -c "import json; d=json.load(open('$sf')); print(sum(1 for v in d.values() if v=='done'))")
    fi
    if [[ -f "$mf" ]]; then
      repos=$(python3 -c "import json; d=json.load(open('$mf')); print(' '.join(f'[{r}]' for r in d.get('repos',[])))")
    fi
    echo -e "  ${ICON_PROJECT} ${BOLD}$p${RESET} ${DIM}($done_count done)${RESET} ${CYAN}$repos${RESET}"
    shown=$((shown + 1))
  done

  if [[ $shown -eq 0 ]]; then
    if [[ "$show_archived" == "true" ]]; then
      echo "  (no archived projects)"
    else
      echo "  (all projects are archived)"
    fi
  fi
  echo ""
}

cmd_archive() {
  local name="${1:-}"; [[ -n "$name" ]] || die "Usage: project archive \"<project>\""
  require_project "$name"
  local mf; mf=$(meta_file "$name")
  python3 -c "
import json, os
mf = '$mf'
data = json.load(open(mf)) if os.path.exists(mf) else {}
data['archived'] = True
json.dump(data, open(mf, 'w'), indent=2)
"
  echo -e "${GREEN}✓ Archived '$name' — hidden from project list${RESET}"
}

cmd_unarchive() {
  local name="${1:-}"; [[ -n "$name" ]] || die "Usage: project unarchive \"<project>\""
  require_project "$name"
  local mf; mf=$(meta_file "$name")
  python3 -c "
import json, os
mf = '$mf'
data = json.load(open(mf)) if os.path.exists(mf) else {}
data.pop('archived', None)
json.dump(data, open(mf, 'w'), indent=2)
"
  echo -e "${GREEN}✓ Unarchived '$name' — visible in project list again${RESET}"
}
