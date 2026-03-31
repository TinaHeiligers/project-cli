#!/usr/bin/env bash
# helpers.sh — Colors, icons, common utilities

PROJECTS_DIR="${HOME}/.projects"

# ─── Colors & Icons ───────────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
DIM="\033[2m"

ICON_DONE="✅"
ICON_WIP="🔄"
ICON_TODO="⬜"
ICON_PROJECT="📁"

# ─── Helpers ──────────────────────────────────────────────────────────────────
die() { echo "❌ Error: $*" >&2; exit 1; }

require_project() {
  local name="$1"
  [[ -d "$PROJECTS_DIR/$name" ]] || die "Project '$name' not found. Run: project new \"$name\""
}

project_dir() { echo "$PROJECTS_DIR/$1"; }
plan_file()   { echo "$PROJECTS_DIR/$1/plan.md"; }
status_file() { echo "$PROJECTS_DIR/$1/status.json"; }
meta_file()   { echo "$PROJECTS_DIR/$1/meta.json"; }
notes_file()  { echo "$PROJECTS_DIR/$1/notes.json"; }

# Build a note key from --phase/--step/--repo/--target flags
# Usage: build_note_key [--phase N] [--step N] [--repo r] [--target t]
# Echoes the key string (e.g. "project", "p2", "p2_s3", "p2_s3_rkibana")
build_note_key() {
  local phase="" step="" repo="" target=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --phase)  phase="${2:-}";  shift 2 ;;
      --step)   step="${2:-}";   shift 2 ;;
      --repo)   repo="${2:-}";   shift 2 ;;
      --target) target="${2:-}"; shift 2 ;;
      *) shift ;;
    esac
  done

  local key="project"
  [[ -n "$phase" ]] && key="p${phase}"
  [[ -n "$step" ]]  && key="p${phase}_s${step}"
  [[ -n "$repo" ]]  && key+="_r${repo}"
  [[ -n "$target" ]] && key+="_t${target}"
  echo "$key"
}
