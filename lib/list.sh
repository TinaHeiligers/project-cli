#!/usr/bin/env bash
# list.sh — List all projects

cmd_list() {
  [[ -d "$PROJECTS_DIR" ]] || { echo "No projects yet. Run: project new \"My Project\""; return; }
  local projects=()
  while IFS= read -r -d '' d; do
    projects+=("$(basename "$d")")
  done < <(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  if [[ ${#projects[@]} -eq 0 ]]; then
    echo "No projects yet. Run: project new \"My Project\""
    return
  fi

  echo -e "\n${BOLD}Projects in $PROJECTS_DIR${RESET}"
  for p in "${projects[@]}"; do
    local sf; sf=$(status_file "$p")
    local mf; mf=$(meta_file "$p")
    local done_count=0
    local repos=""
    if [[ -f "$sf" ]]; then
      done_count=$(python3 -c "import json; d=json.load(open('$sf')); print(sum(1 for v in d.values() if v=='done'))")
    fi
    if [[ -f "$mf" ]]; then
      repos=$(python3 -c "import json; d=json.load(open('$mf')); print(' '.join(f'[{r}]' for r in d.get('repos',[])))")
    fi
    echo -e "  ${ICON_PROJECT} ${BOLD}$p${RESET} ${DIM}($done_count done)${RESET} ${CYAN}$repos${RESET}"
  done
  echo ""
}
