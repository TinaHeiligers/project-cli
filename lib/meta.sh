#!/usr/bin/env bash
# meta.sh — Meta helpers (repos + targets) and set_status

get_meta() {
  local proj="$1" key="$2"
  local mf; mf=$(meta_file "$proj")
  python3 -c "
import json, os
mf = '$mf'
data = json.load(open(mf)) if os.path.exists(mf) else {}
val = data.get('$key', [])
print(' '.join(val))
" 2>/dev/null || echo ""
}

set_meta_add() {
  local proj="$1" key="$2" value="$3"
  local mf; mf=$(meta_file "$proj")
  python3 -c "
import json, os
mf = '$mf'
data = json.load(open(mf)) if os.path.exists(mf) else {}
lst = data.get('$key', [])
if '$value' not in lst:
    lst.append('$value')
data['$key'] = lst
json.dump(data, open(mf, 'w'), indent=2)
"
}

set_meta_remove() {
  local proj="$1" key="$2" value="$3"
  local mf; mf=$(meta_file "$proj")
  python3 -c "
import json, os
mf = '$mf'
data = json.load(open(mf)) if os.path.exists(mf) else {}
lst = data.get('$key', [])
data['$key'] = [x for x in lst if x != '$value']
json.dump(data, open(mf, 'w'), indent=2)
"
}

set_status() {
  local proj="$1" key="$2" value="$3"
  local sf; sf=$(status_file "$proj")
  python3 -c "
import json, os
sf = '$sf'
data = json.load(open(sf)) if os.path.exists(sf) else {}
data['$key'] = '$value'
json.dump(data, open(sf, 'w'), indent=2)
"
}

cmd_repo() {
  local name="${1:-}" action="${2:-}" value="${3:-}"
  [[ -n "$name" && -n "$action" ]] || die "Usage: project repo \"<project>\" add|remove|list <name>"
  require_project "$name"
  case "$action" in
    add)
      [[ -n "$value" ]] || die "Usage: project repo \"<project>\" add <reponame>"
      set_meta_add "$name" "repos" "$value"
      echo -e "${GREEN}✓ Added repo '$value' to '$name'${RESET}"
      ;;
    remove)
      [[ -n "$value" ]] || die "Usage: project repo \"<project>\" remove <reponame>"
      set_meta_remove "$name" "repos" "$value"
      echo -e "${GREEN}✓ Removed repo '$value' from '$name'${RESET}"
      ;;
    list)
      local repos; repos=$(get_meta "$name" "repos")
      echo "Repos: ${repos:-none}"
      ;;
    *) die "Unknown action '$action'. Use: add, remove, list" ;;
  esac
}

cmd_target() {
  local name="${1:-}" action="${2:-}" value="${3:-}"
  [[ -n "$name" && -n "$action" ]] || die "Usage: project target \"<project>\" add|remove|list <name>"
  require_project "$name"
  case "$action" in
    add)
      [[ -n "$value" ]] || die "Usage: project target \"<project>\" add <targetname>"
      set_meta_add "$name" "targets" "$value"
      echo -e "${GREEN}✓ Added target '$value' to '$name'${RESET}"
      ;;
    remove)
      [[ -n "$value" ]] || die "Usage: project target \"<project>\" remove <targetname>"
      set_meta_remove "$name" "targets" "$value"
      echo -e "${GREEN}✓ Removed target '$value' from '$name'${RESET}"
      ;;
    list)
      local targets; targets=$(get_meta "$name" "targets")
      echo "Targets: ${targets:-none}"
      ;;
    *) die "Unknown action '$action'. Use: add, remove, list" ;;
  esac
}
