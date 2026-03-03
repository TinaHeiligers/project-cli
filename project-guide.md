# `project` — How To Use Guide

## Recommended Models:

- Sonnet + high effort — best balance, start here
- Opus + high effort — if the project is very complex or Sonnet gets confused
- Sonnet medium effort — if the project is small and straightforward and you just want it fast

## Concepts

Every project has:

- **Phases** — major chunks of work (e.g. "Phase 1: Implementation")
- **Steps** — individual tasks within a phase
- **Repos** — the git repositories involved in this epic
- **Targets** — deployment targets (e.g. `local`, `remote`, `staging`)

Steps track progress at three levels of granularity:

| Type | When to use | Tracked by |
|------|-------------|------------|
| Simple | No repo/target context needed | done / wip / todo |
| Per-repo | Step touches specific repos (e.g. writing code) | one entry per repo |
| Repo × target | Step applies something to a deployment target | one entry per repo+target combo |

Plans are stored in `~/.projects/` as plain Markdown (`plan.md`) + JSON (`status.json`, `meta.json`). You can back this up or sync with iCloud/Dropbox to keep it across laptops.

---

## Installation

```bash
chmod +x project
sudo mv project /usr/local/bin/project
```

Or add the folder containing it to your PATH in `~/.zshrc`:
```bash
export PATH="$HOME/Projects/assistant-tooling/own-tooling/files:$PATH"
```

---

## Command Reference

### Setup

```bash
project new "Name"                           # Create a new project
project repo   "Name" add|remove|list <r>   # Manage repos
project target "Name" add|remove|list <t>   # Manage targets
```

### Building the plan

```bash
project phase "Name" "Phase title"          # Add a phase

project step "Name" <phase#> "Title"                          # Simple step
project step "Name" <phase#> "Title" --repos r1,r2            # Repo-only step
project step "Name" <phase#> "Title" --repos r1,r2 \
                                     --targets t1,t2          # Repo×target step
```

### Marking progress

```bash
# Simple step
project start "Name" <phase#> <step#>
project done  "Name" <phase#> <step#>
project reset "Name" <phase#> <step#>

# Repo-only step — mark each repo separately
project start "Name" <phase#> <step#> --repo <r>
project done  "Name" <phase#> <step#> --repo <r>

# Repo×target step — mark each combination separately
project done  "Name" <phase#> <step#> --repo <r> --target <t>
project start "Name" <phase#> <step#> --repo <r> --target <t>
```

### Viewing

```bash
project status "Name"    # Full project tree with rollup icons
project list             # All projects with repo summary
project edit "Name"      # Open plan.md in $EDITOR
project guide            # Show this guide in terminal
project help             # Show command reference
```

---

## Full Example: Terraform Provider Epic

### 1. Create project and declare repos/targets

```bash
project new "Terraform Provider"

project repo   "Terraform Provider" add provider
project repo   "Terraform Provider" add repoA
project repo   "Terraform Provider" add repoB

project target "Terraform Provider" add local
project target "Terraform Provider" add remote
```

### 2. Add phases

```bash
project phase "Terraform Provider" "Implementation"
project phase "Terraform Provider" "Apply Resources"
project phase "Terraform Provider" "Validation"
```

### 3. Add steps

```bash
# Simple step — no tracking context needed
project step "Terraform Provider" 1 "Design resource schema"

# Repo-only — writing code touches specific repos
project step "Terraform Provider" 1 "Implement resource CRUD" \
  --repos provider,repoA

# Repo×target — applying resources involves repos AND targets
project step "Terraform Provider" 2 "Apply terraform resources" \
  --repos repoA,repoB --targets local,remote

# Simple step again
project step "Terraform Provider" 3 "Write acceptance tests"
```

### 4. Mark progress as you work

```bash
# Simple step
project done "Terraform Provider" 1 1

# Repo-only step: each repo tracked separately
project done  "Terraform Provider" 1 2 --repo provider
project start "Terraform Provider" 1 2 --repo repoA

# Repo×target step: each combination tracked separately
project done  "Terraform Provider" 2 1 --repo repoA --target local
project start "Terraform Provider" 2 1 --repo repoA --target remote
project start "Terraform Provider" 2 1 --repo repoB --target local
# repoB → remote not started yet
```

### 5. Check where you are

```bash
project status "Terraform Provider"
```

```
📁 Terraform Provider
Repos:   [provider]  [repoA]  [repoB]
Targets: [local]  [remote]

├── 🔄 Phase 1: Implementation
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
```

Phase icons roll up automatically — a phase shows 🔄 if any step is in progress, ✅ only when every tracking unit inside it is done.

---

## Simpler Example: One Repo, No Targets

```bash
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
```

---

## Migrating an Existing Project

Most projects don't start from scratch. If your context is scattered across desktop files, Claude's memory, and git branches, use this workflow to reconstruct a clean structure.

### Where things end up

```
~/.projects/My Project/
  plan.md          ← the phase/step hierarchy
  status.json      ← progress tracking
  meta.json        ← repos and targets
  refs/            ← key reference files copied here
    architecture.md
    decisions.md
```

Files that are large, rarely consulted, or already version-controlled stay where they are — just referenced by path inside `plan.md`.

---

### Step 1 — Gather your inputs

Collect everything relevant before starting:

- Planning docs, update notes, progress logs from your desktop
- Any files from Claude's project root
- Branch names and what's on each (you don't need the code, just the names)
- Anything you remember that isn't written down yet

Messy is fine — that's what the next step is for.

---

### Step 2 — Ask Claude to reconstruct the structure

Start a new Claude conversation and paste this prompt, attaching your files:

**Migration prompt template:**

```
I want to migrate an existing project into my `project` CLI tool.
The tool uses this structure: Epic → Phases → Steps, where steps can be
tagged with --repos and --targets for granular tracking.

Here is my existing context (files attached / pasted below):
[attach or paste your files here]

Please:
1. Read through everything and identify what's already DONE, what's IN PROGRESS,
   and what's still PENDING
2. Propose a clean phase → step breakdown, grouped logically
3. For each step, suggest whether it needs --repos and/or --targets tags
4. Flag anything ambiguous where you need my input before proceeding
5. Once I approve the structure, generate the exact `project` CLI commands
   to set it all up, including the correct `project done` and `project start`
   commands to reflect current progress

My repos for this epic are: [list them]
My targets (if any) are: [list them, or say "none"]
```

---

### Step 3 — Review and approve

Claude will propose something like:

```
Phase 1: Provider Implementation  ← DONE
  - Design schema                 ← done
  - Implement CRUD                ← done [provider, repoA]

Phase 2: Apply Resources          ← IN PROGRESS
  - Apply to local                ← done [repoA→local, repoB→local]
  - Apply to remote               ← in progress [repoA→remote], pending [repoB→remote]

Phase 3: Validation               ← PENDING
  - Write acceptance tests
  - Sign-off
```

Push back on anything that doesn't look right before moving on.

---

### Step 4 — Run the generated commands

Claude will output a ready-to-run block. Copy, paste, run. Then verify:

```bash
project status "Terraform Provider"
```

---

### Step 5 — Handle reference files

**Copy it** (critical, frequently consulted):
```bash
mkdir -p ~/.projects/"My Project"/refs
cp ~/Desktop/architecture.md ~/.projects/"My Project"/refs/
```

**Reference it** (large, stable, already version-controlled) — add a References section via:
```bash
project edit "My Project"
```

Then add at the bottom of `plan.md`:
```markdown
## References

- Architecture: ~/Desktop/architecture.md
- Provider spec: ~/Projects/terraform-provider/docs/spec.md
- Branch map:
  - provider: feat/resource-v2
  - repoA: feat/apply-new-provider
  - repoB: main
```

---

### Step 6 — Verify

```bash
project status "My Project"   # check the tree looks right
project list                  # confirm it shows up
```

If anything is wrong, reset individual units:
```bash
project reset "My Project" 2 1 --repo repoB --target remote
```

---

## Tips

- **Edit the plan directly** — `project edit "Name"` opens `plan.md` in your `$EDITOR`. Keep the `## Phase N: Title` format on phase header lines and `- [ ] ...` format for steps.
- **Remove a repo/target** — `project repo "Name" remove repoA` (does not affect existing status entries).
- **Reset a unit** — `project reset "Name" 1 2 --repo repoA` sets it back to todo.
- **Backup** — sync `~/.projects/` with iCloud Drive, Dropbox, or commit it to your dotfiles repo.
