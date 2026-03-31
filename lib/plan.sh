#!/usr/bin/env bash
# plan.sh — Project creation, phases, steps, marking progress

cmd_new() {
  local name="${1:-}"; [[ -n "$name" ]] || die "Usage: project new \"<name>\""
  local dir; dir=$(project_dir "$name")
  [[ ! -d "$dir" ]] || die "Project '$name' already exists."
  mkdir -p "$dir"
  cat > "$(plan_file "$name")" <<EOF
# $name

> Created: $(date '+%Y-%m-%d')
EOF
  echo '{}' > "$(status_file "$name")"
  echo '{"repos":[],"targets":[]}' > "$(meta_file "$name")"
  echo '{}' > "$(notes_file "$name")"
  echo -e "${GREEN}✓ Created project '${BOLD}$name${RESET}${GREEN}' in $dir${RESET}"
  echo -e "${DIM}  Next: add repos with 'project repo \"$name\" add <repo>'${RESET}"
}

cmd_phase() {
  local name="${1:-}" title="${2:-}"
  [[ -n "$name" && -n "$title" ]] || die "Usage: project phase \"<project>\" \"<phase title>\""
  require_project "$name"

  local pf; pf=$(plan_file "$name")
  local num; num=$(grep -c "^## Phase " "$pf" 2>/dev/null || true)
  num=$((num + 1))

  cat >> "$pf" <<EOF

## Phase $num: $title
EOF
  echo -e "${GREEN}✓ Added Phase $num: $title${RESET}"
}

cmd_step() {
  local name="${1:-}" phase_num="${2:-}" title="${3:-}"
  [[ -n "$name" && -n "$phase_num" && -n "$title" ]] || \
    die "Usage: project step \"<project>\" <phase#> \"<title>\" [--repos r1,r2] [--targets t1,t2]"
  require_project "$name"
  shift 3

  local repos="" targets=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repos)   repos="${2:-}";   shift 2 ;;
      --targets) targets="${2:-}"; shift 2 ;;
      *) die "Unknown option '$1'" ;;
    esac
  done

  local tags=""
  [[ -n "$repos" ]]   && tags+=" @repos:$repos"
  [[ -n "$targets" ]] && tags+=" @targets:$targets"

  local pf; pf=$(plan_file "$name")

  python3 -c "
lines = open('$pf').readlines()
in_phase = False
insert_at = None
for i, line in enumerate(lines):
    if line.startswith('## Phase $phase_num:'):
        in_phase = True
    elif in_phase and line.startswith('## Phase '):
        insert_at = i
        break
if in_phase and insert_at is None:
    insert_at = len(lines)
lines.insert(insert_at, '- [ ] $title$tags\n')
open('$pf', 'w').writelines(lines)
"
  echo -e "${GREEN}✓ Added step to Phase $phase_num: $title${RESET}"
  if [[ -n "$tags" ]]; then echo -e "${DIM}  Tags:$tags${RESET}"; fi
}

cmd_mark() {
  local state="$1" name="${2:-}" phase_num="${3:-}" step_num="${4:-}"
  [[ -n "$name" && -n "$phase_num" && -n "$step_num" ]] || \
    die "Usage: project $state \"<project>\" <phase#> <step#> [--repo <repo>] [--target <target>]"
  require_project "$name"
  shift 4

  local repo="" target=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo)   repo="${2:-}";   shift 2 ;;
      --target) target="${2:-}"; shift 2 ;;
      *) die "Unknown option '$1'" ;;
    esac
  done

  local key="p${phase_num}_s${step_num}"
  [[ -n "$repo" ]]   && key+="_r${repo}"
  [[ -n "$target" ]] && key+="_t${target}"

  set_status "$name" "$key" "$state"

  local desc="Step $step_num of Phase $phase_num"
  [[ -n "$repo" ]]   && desc+=" [${repo}]"
  [[ -n "$target" ]] && desc+=" → ${target}"
  echo -e "${GREEN}✓ $desc marked as $state${RESET}"
}

cmd_edit() {
  local name="${1:-}"; [[ -n "$name" ]] || die "Usage: project edit \"<project>\""
  require_project "$name"
  ${EDITOR:-nano} "$(plan_file "$name")"
}
