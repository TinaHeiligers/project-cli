#!/usr/bin/env bash
# status.sh — Project status tree display

cmd_status() {
  local name="${1:-}"; [[ -n "$name" ]] || die "Usage: project status \"<project>\" [--no-notes] [--notes-since <date>] [--all-notes] [--compact]"
  require_project "$name"
  shift

  local notes_mode="default" notes_since="" compact=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-notes)    notes_mode="none";    shift ;;
      --all-notes)   notes_mode="all";     shift ;;
      --notes-since) notes_mode="since"; notes_since="${2:-}"; shift 2 ;;
      --compact)     compact=true;         shift ;;
      *) die "Unknown option '$1'" ;;
    esac
  done

  local pf; pf=$(plan_file "$name")
  local sf; sf=$(status_file "$name")
  local mf; mf=$(meta_file "$name")
  local nf; nf=$(notes_file "$name")

  echo -e "\n${BOLD}${ICON_PROJECT} $name${RESET}"

  python3 - "$pf" "$sf" "$mf" "$nf" "$notes_mode" "$notes_since" "$compact" <<'PYEOF'
import json, sys, re, os
from datetime import datetime, timedelta

pf, sf, mf, nf = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
notes_mode = sys.argv[5]
notes_since = sys.argv[6]
compact = sys.argv[7] == "true"
status = json.load(open(sf)) if os.path.exists(sf) else {}
meta   = json.load(open(mf)) if os.path.exists(mf) else {}
notes  = json.load(open(nf)) if os.path.exists(nf) else {}

repos   = meta.get("repos", [])
targets = meta.get("targets", [])

DONE  = "✅"
WIP   = "🔄"
TODO  = "⬜"
RESET = "\033[0m"
BOLD  = "\033[1m"
DIM   = "\033[2m"
CYAN  = "\033[36m"

def icon(s):
    if s == "done": return DONE
    if s in ("wip", "start", "started", "in-progress"): return WIP
    return TODO

def rollup_icon(statuses):
    vals = list(statuses)
    if not vals: return TODO
    if all(v == "done" for v in vals): return DONE
    if any(v in ("wip","start","started","in-progress","done") for v in vals): return WIP
    return TODO

NOTE_ICON = "📝"

# Determine date cutoff for notes
if notes_mode == "none" or compact:
    date_cutoff = None
    show_notes = False
elif notes_mode == "all":
    date_cutoff = None
    show_notes = True
elif notes_mode == "since":
    date_cutoff = notes_since
    show_notes = True
else:  # default: last 7 days
    date_cutoff = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")
    show_notes = True

hidden_count = 0

def print_notes(key, prefix):
    global hidden_count
    if not show_notes:
        return
    for note in notes.get(key, []):
        if date_cutoff and note["date"] < date_cutoff:
            hidden_count += 1
            continue
        nid = note.get('id', '?')
        print(f"{prefix}{NOTE_ICON} #{nid} {DIM}{note['date']}{RESET} {note['text']}")

# Print epic-level repo/target header
if repos:
    print(f"Repos:   " + "  ".join(f"[{r}]" for r in repos))
if targets:
    print(f"Targets: " + "  ".join(f"[{t}]" for t in targets))
if repos or targets:
    print()

# Project-level notes
print_notes("project", "  ")

# Parse plan.md
lines = open(pf).readlines()
phases = []
current_phase = None

for line in lines:
    line = line.rstrip()
    m = re.match(r'^## Phase (\d+):(.*)', line)
    if m:
        current_phase = {"num": int(m.group(1)), "title": m.group(2).strip(), "steps": []}
        phases.append(current_phase)
    elif current_phase and re.match(r'^- \[', line):
        text = re.sub(r'^- \[.\] ', '', line).strip()
        step_repos_m   = re.search(r'@repos:([^\s]+)', text)
        step_targets_m = re.search(r'@targets:([^\s]+)', text)
        step_repos   = step_repos_m.group(1).split(',')   if step_repos_m   else []
        step_targets = step_targets_m.group(1).split(',') if step_targets_m else []
        clean_title  = re.sub(r'\s*@repos:\S+', '', re.sub(r'\s*@targets:\S+', '', text)).strip()
        current_phase["steps"].append({
            "title": clean_title,
            "repos": step_repos,
            "targets": step_targets,
        })

total_units = 0
done_units  = 0
wip_units   = 0

for pi, phase in enumerate(phases):
    pn = phase["num"]
    is_last_phase = (pi == len(phases) - 1)
    branch = "└──" if is_last_phase else "├──"
    connector = "    " if is_last_phase else "│   "

    phase_statuses = []

    step_lines = []
    for si, step in enumerate(phase["steps"]):
        sn = si + 1
        base_key = f"p{pn}_s{sn}"
        is_last_step = (si == len(phase["steps"]) - 1)
        sbranch = "└──" if is_last_step else "├──"
        sconnector = "    " if is_last_step else "│   "

        step_repos   = step["repos"]
        step_targets = step["targets"]

        if step_repos and step_targets:
            unit_statuses = []
            sub_lines = []
            for r in step_repos:
                for t in step_targets:
                    key = f"{base_key}_r{r}_t{t}"
                    s = status.get(key, "todo")
                    unit_statuses.append(s)
                    phase_statuses.append(s)
                    total_units += 1
                    if s == "done": done_units += 1
                    elif s in ("wip","start","started","in-progress"): wip_units += 1
                    sub_lines.append((r, t, s))
            step_icon = rollup_icon(unit_statuses)
            step_lines.append((sbranch, sconnector, step_icon, step["title"], sub_lines, "matrix"))

        elif step_repos:
            unit_statuses = []
            sub_lines = []
            for r in step_repos:
                key = f"{base_key}_r{r}"
                s = status.get(key, "todo")
                unit_statuses.append(s)
                phase_statuses.append(s)
                total_units += 1
                if s == "done": done_units += 1
                elif s in ("wip","start","started","in-progress"): wip_units += 1
                sub_lines.append((r, None, s))
            step_icon = rollup_icon(unit_statuses)
            step_lines.append((sbranch, sconnector, step_icon, step["title"], sub_lines, "repos"))

        else:
            s = status.get(base_key, "todo")
            phase_statuses.append(s)
            total_units += 1
            if s == "done": done_units += 1
            elif s in ("wip","start","started","in-progress"): wip_units += 1
            step_lines.append((sbranch, sconnector, icon(s), step["title"], [], "simple"))

    phase_icon = rollup_icon(phase_statuses) if phase_statuses else TODO
    done_in_phase = sum(1 for s in phase_statuses if s == "done")
    total_in_phase = len(phase_statuses)

    if compact:
        print(f"{branch} {phase_icon} {BOLD}Phase {pn}: {phase['title']}{RESET} {DIM}({done_in_phase}/{total_in_phase}){RESET}")
    else:
        print(f"{branch} {phase_icon} {BOLD}Phase {pn}: {phase['title']}{RESET}")
        print_notes(f"p{pn}", connector)

        for idx, (sbranch, sconnector, step_icon, title, sub_lines, mode) in enumerate(step_lines):
            sn = idx + 1
            is_last = (idx == len(step_lines) - 1)
            step_prefix = connector + ("    " if is_last else "│   ")
            print(f"{connector}{sbranch} {step_icon} {title}")
            print_notes(f"p{pn}_s{sn}", step_prefix)

            if mode in ("matrix", "repos"):
                sub_connector = connector + ("    " if is_last else "│   ")
                for li, (r, t, s) in enumerate(sub_lines):
                    is_last_sub = (li == len(sub_lines) - 1)
                    subbranch = "└──" if is_last_sub else "├──"
                    sub_note_prefix = sub_connector + ("    " if is_last_sub else "│   ")
                    if t:
                        print(f"{sub_connector}{subbranch} {icon(s)} [{r}] → {t}")
                        print_notes(f"p{pn}_s{sn}_r{r}_t{t}", sub_note_prefix)
                    else:
                        print(f"{sub_connector}{subbranch} {icon(s)} [{r}]")
                        print_notes(f"p{pn}_s{sn}_r{r}", sub_note_prefix)

if not phases:
    print("    (no phases yet)")

progress = f"\n{DIM}Progress: {done_units}/{total_units} units done, {wip_units} in progress{RESET}"
if hidden_count > 0:
    progress += f"\n{DIM}({hidden_count} older note(s) hidden — use --all-notes to show){RESET}"
print(progress)
PYEOF
  echo ""
}
