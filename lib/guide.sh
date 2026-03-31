#!/usr/bin/env bash
# guide.sh — Help and guide commands

cmd_help() {
  local B=$'\033[1m' R=$'\033[0m'
  printf "\n"
  printf "${B}project${R} — Hierarchical project plan tracker\n"
  printf "Plans stored in: ${B}~/.projects/${R}\n"
  printf "\n"
  printf "${B}SETUP COMMANDS${R}\n"
  printf '  project new "Name"                              Create a new project\n'
  printf '  project repo "Name" add|remove|list <repo>     Manage repos for a project\n'
  printf '  project target "Name" add|remove|list <target> Manage targets for a project\n'
  printf "\n"
  printf "${B}PLAN COMMANDS${R}\n"
  printf '  project phase "Name" "Phase title"             Add a phase\n'
  printf '  project step "Name" <phase#> "Title"           Add a simple step\n'
  printf '  project step "Name" <phase#> "Title" \\\n'
  printf '    --repos r1,r2 --targets t1,t2               Add a step with repo/target tracking\n'
  printf "\n"
  printf "${B}PROGRESS COMMANDS${R}\n"
  printf '  project start "Name" <phase#> <step#>          Mark simple step in progress\n'
  printf '  project done  "Name" <phase#> <step#>          Mark simple step done\n'
  printf '  project reset "Name" <phase#> <step#>          Reset simple step to todo\n'
  printf "\n"
  printf '  project start "Name" <phase#> <step#> --repo <r>              Repo-only step\n'
  printf '  project done  "Name" <phase#> <step#> --repo <r>\n'
  printf '  project done  "Name" <phase#> <step#> --repo <r> --target <t> Repo*target step\n'
  printf "\n"
  printf "${B}NOTE COMMANDS${R}\n"
  printf '  project note "Name" "text"                         Add project-level note\n'
  printf '  project note "Name" <phase#> "text"                Add phase-level note\n'
  printf '  project note "Name" <phase#> <step#> "text"        Add step-level note\n'
  printf '  project note "Name" <phase#> <step#> "text" \\\n'
  printf '    --repo <r> --target <t>                          Add note to repo/target\n'
  printf '  project note "Name" delete <id>                    Delete note by ID\n'
  printf '  project note "Name" delete --before <date>         Delete notes before date\n'
  printf '  project note "Name" delete --all                   Delete all notes (scope with --phase/--step)\n'
  printf '  project note "Name" archive <id>                   Archive note by ID\n'
  printf '  project note "Name" archive --before <date>        Archive notes before date\n'
  printf '  project note "Name" edit <id> "new text"           Edit a note\n'
  printf '  project notes "Name"                               List all notes\n'
  printf '  project notes "Name" --archived                    List archived notes\n'
  printf "\n"
  printf "${B}VIEW COMMANDS${R}\n"
  printf '  project status "Name"                          Show tree (notes from last 7 days)\n'
  printf '  project status "Name" --all-notes              Show tree with all notes\n'
  printf '  project status "Name" --no-notes               Show tree without notes\n'
  printf '  project status "Name" --notes-since <date>     Show notes since date\n'
  printf '  project status "Name" --compact                One line per phase\n'
  printf '  project list                                   List active projects\n'
  printf '  project list --archived                        List archived projects\n'
  printf '  project edit "Name"                            Open plan.md in $EDITOR\n'
  printf "\n"
  printf "${B}PROJECT MANAGEMENT${R}\n"
  printf '  project archive "Name"                         Hide from project list\n'
  printf '  project unarchive "Name"                       Restore to project list\n'
  printf '  project migrate "Name"                         Migrate notes to use IDs\n'
  printf '  project migrate --all                          Migrate all projects\n'
  printf "\n"
  printf "${B}EXAMPLE${R}\n"
  printf '  See: project guide\n'
  printf "\n"
}

cmd_guide() {
  cat <<'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  project — How To Use Guide
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CONCEPTS
────────
Every project has:
  • Phases   — major chunks of work (e.g. "Phase 1: Implementation")
  • Steps    — individual tasks within a phase
  • Repos    — the git repositories involved in this epic
  • Targets  — deployment targets (e.g. local, remote, staging)

Steps can track progress at three levels of granularity:
  1. Simple        — just done/wip/todo (no repos or targets)
  2. Per-repo      — tracked separately for each repo
  3. Repo×target   — tracked for every repo+target combination

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EXAMPLE: Terraform Provider Epic
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1 — Create the project and declare repos/targets
─────────────────────────────────────────────────────
  project new "Terraform Provider"
  project repo   "Terraform Provider" add provider
  project repo   "Terraform Provider" add repoA
  project repo   "Terraform Provider" add repoB
  project target "Terraform Provider" add local
  project target "Terraform Provider" add remote

STEP 2 — Add phases
────────────────────
  project phase "Terraform Provider" "Implementation"
  project phase "Terraform Provider" "Apply Resources"
  project phase "Terraform Provider" "Validation"

STEP 3 — Add steps (mix of simple, repo-only, and repo×target)
───────────────────────────────────────────────────────────────
  # Simple step — no repo/target tracking
  project step "Terraform Provider" 1 "Design resource schema"

  # Repo-only step — track per repo
  project step "Terraform Provider" 1 "Implement resource CRUD" \
    --repos provider,repoA

  # Repo×target step — track each repo against each target
  project step "Terraform Provider" 2 "Apply terraform resources" \
    --repos repoA,repoB --targets local,remote

  # Simple step
  project step "Terraform Provider" 3 "Write acceptance tests"

STEP 4 — Mark progress
───────────────────────
  # Simple step
  project start "Terraform Provider" 1 1
  project done  "Terraform Provider" 1 1

  # Repo-only step: mark each repo separately
  project done  "Terraform Provider" 1 2 --repo provider
  project start "Terraform Provider" 1 2 --repo repoA

  # Repo×target step: mark each combination separately
  project done  "Terraform Provider" 2 1 --repo repoA --target local
  project start "Terraform Provider" 2 1 --repo repoA --target remote
  project start "Terraform Provider" 2 1 --repo repoB --target local
  # repoB → remote not started yet

STEP 5 — Check where you are
──────────────────────────────
  project status "Terraform Provider"

OUTPUT:
  📁 Terraform Provider
  Repos:   [provider]  [repoA]  [repoB]
  Targets: [local]  [remote]

  ├── ✅ Phase 1: Implementation
  │   ├── ✅ Design resource schema
  │   └── 🔄 Implement resource CRUD
  │       ├── ✅ [provider]
  │       └── 🔄 [repoA]
  ├── 🔄 Phase 2: Apply Resources
  │   └── 🔄 Apply terraform resources
  │       ├── ✅ [repoA] → local
  │       ├── 🔄 [repoA] → remote
  │       ├── 🔄 [repoB] → local
  │       └── ⬜ [repoB] → remote
  └── ⬜ Phase 3: Validation
      └── ⬜ Write acceptance tests

  Progress: 3/8 units done, 3 in progress

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SIMPLER EPIC EXAMPLE (one repo, no targets)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  project new "Fix Auth Bug"
  project repo "Fix Auth Bug" add my-api

  project phase "Fix Auth Bug" "Investigation"
  project step  "Fix Auth Bug" 1 "Reproduce the bug"
  project step  "Fix Auth Bug" 1 "Find root cause" --repos my-api

  project phase "Fix Auth Bug" "Fix"
  project step  "Fix Auth Bug" 2 "Write failing test" --repos my-api
  project step  "Fix Auth Bug" 2 "Implement fix"      --repos my-api

  project done  "Fix Auth Bug" 1 1
  project done  "Fix Auth Bug" 1 2 --repo my-api
  project start "Fix Auth Bug" 2 1 --repo my-api

  project status "Fix Auth Bug"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MIGRATING AN EXISTING PROJECT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If your project context is scattered across desktop files, Claude memory,
and git branches, use this workflow:

STEP 1 — Gather your inputs
  Collect planning docs, update notes, progress logs, and branch names.
  Messy is fine.

STEP 2 — Ask Claude to reconstruct the structure
  Start a new Claude conversation, attach your files, and paste this:

  ┌─────────────────────────────────────────────────────────────┐
  │ I want to migrate an existing project into my `project`     │
  │ CLI tool (Epic → Phases → Steps, with --repos/--targets).   │
  │                                                             │
  │ [attach your files]                                         │
  │                                                             │
  │ Please:                                                     │
  │ 1. Identify what's DONE, IN PROGRESS, and PENDING           │
  │ 2. Propose a clean phase → step breakdown                   │
  │ 3. Suggest --repos/--targets tags where relevant            │
  │ 4. Flag anything ambiguous                                  │
  │ 5. After I approve, generate the exact `project` commands   │
  │                                                             │
  │ Repos: [list them]   Targets: [list them or "none"]         │
  └─────────────────────────────────────────────────────────────┘

STEP 3 — Review Claude's proposed structure and push back on anything wrong.

STEP 4 — Run the generated commands, then verify:
  project status "My Project"

STEP 5 — Handle reference files
  Copy key ones:   cp ~/Desktop/spec.md ~/.projects/"My Project"/refs/
  Reference others: project edit "My Project"  →  add a ## References section

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Phase icons roll up automatically — a phase shows 🔄 if any step is
  in progress, ✅ only when all tracking units are done.

• You can always open and edit plan.md directly:
    project edit "My Project"
  Just keep the ## Phase N: Title format on phase lines.

• To see all your projects:
    project list

• To remove a repo or target from an epic:
    project repo "Name" remove repoA
    project target "Name" remove local

• Plans live in ~/.projects/ — back this up or sync it with
  iCloud/Dropbox to keep it across laptops.

EOF
}
