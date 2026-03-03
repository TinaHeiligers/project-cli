# project

A CLI tool for tracking multi-phase project plans with per-repo and per-target progress tracking. Built for engineers who work across multiple repositories and deployment targets.

Plans are stored as plain Markdown + JSON in `~/.projects/` — no database, no server, no account required.

```
project status "Terraform Provider"

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
```

## Requirements

- Bash 4+
- Python 3 (used internally for JSON manipulation)

Both are pre-installed on macOS and most Linux distributions.

## Installation

### Option 1: Copy to PATH

```bash
curl -fsSL https://raw.githubusercontent.com/TinaHeiligers/project-cli/main/project -o project
chmod +x project
sudo mv project /usr/local/bin/project
```

### Option 2: Clone and symlink

```bash
git clone https://github.com/TinaHeiligers/project-cli.git
cd project-cli
chmod +x project
sudo ln -sf "$(pwd)/project" /usr/local/bin/project
```

### Option 3: Add to PATH

```bash
git clone https://github.com/TinaHeiligers/project-cli.git
# Add to your shell profile (~/.zshrc or ~/.bashrc):
export PATH="$HOME/project-cli:$PATH"
```

Verify the installation:

```bash
project help
```

## Quick start

```bash
# Create a project
project new "My Feature"

# Add repos involved
project repo "My Feature" add backend
project repo "My Feature" add frontend

# Add phases and steps
project phase "My Feature" "Implementation"
project step  "My Feature" 1 "Write API endpoint" --repos backend
project step  "My Feature" 1 "Build UI component" --repos frontend

project phase "My Feature" "Testing"
project step  "My Feature" 2 "Integration tests"

# Track progress
project start "My Feature" 1 1 --repo backend
project done  "My Feature" 1 1 --repo backend

# Check status
project status "My Feature"
```

## Concepts

Every project has:

- **Phases** — major chunks of work (e.g. "Phase 1: Implementation")
- **Steps** — individual tasks within a phase
- **Repos** — git repositories involved in the project
- **Targets** — deployment targets (e.g. `local`, `remote`, `staging`)

Steps track progress at three levels:

| Type | When to use | Example |
|------|-------------|---------|
| Simple | No repo/target context needed | "Write design doc" |
| Per-repo | Step touches specific repos | "Implement CRUD" across 2 repos |
| Repo x target | Step applies to repo+target combos | "Deploy service" across repos and environments |

Phase icons roll up automatically — a phase shows 🔄 if any step is in progress, ✅ only when every tracking unit is done.

## Command reference

### Setup

```bash
project new "Name"                              # Create a new project
project repo   "Name" add|remove|list <repo>    # Manage repos
project target "Name" add|remove|list <target>  # Manage targets
```

### Building the plan

```bash
project phase "Name" "Phase title"              # Add a phase

project step "Name" <phase#> "Title"            # Simple step
project step "Name" <phase#> "Title" \
  --repos r1,r2                                 # Per-repo step
project step "Name" <phase#> "Title" \
  --repos r1,r2 --targets t1,t2                 # Repo x target step
```

### Marking progress

```bash
# Simple step
project start "Name" <phase#> <step#>
project done  "Name" <phase#> <step#>
project reset "Name" <phase#> <step#>

# Per-repo step
project start "Name" <phase#> <step#> --repo <r>
project done  "Name" <phase#> <step#> --repo <r>

# Repo x target step
project done  "Name" <phase#> <step#> --repo <r> --target <t>
```

### Notes

Attach timestamped notes at any level — they show inline in `project status`.

```bash
project note "Name" "text"                                    # Project-level
project note "Name" <phase#> "text"                           # Phase-level
project note "Name" <phase#> <step#> "text"                   # Step-level
project note "Name" <phase#> <step#> "text" --repo <r>        # Repo-level
project note "Name" <phase#> <step#> "text" \
  --repo <r> --target <t>                                     # Repo x target

project notes "Name"                                          # List all notes
```

### Viewing

```bash
project status "Name"     # Full project tree with rollup icons
project list              # All projects
project edit "Name"       # Open plan.md in $EDITOR
project guide             # Detailed usage guide in terminal
project help              # Command reference
```

## AI assistant integration

The `project` CLI works well with AI coding assistants. Drop the appropriate instruction file into your project to teach the assistant how to use the tool:

| Assistant | File | Where to put it |
|-----------|------|-----------------|
| GitHub Copilot | `copilot-instructions.md` | `.github/copilot-instructions.md` |
| Cursor | `cursor-project-tracking.mdc` | `.cursor/rules/cursor-project-tracking.mdc` |
| Claude Code | Add contents to `CLAUDE.md` | `CLAUDE.md` in your project root |

These instruction files teach the assistant to:
- Use `project list` and `project status` to find projects and steps
- Use the correct `project done/start/reset` commands with `--repo` and `--target` flags
- Follow a consistent workflow when the user says "mark X as done"

## Data storage

All data lives in `~/.projects/<project-name>/`:

```
~/.projects/My Feature/
  plan.md          # Phase and step hierarchy (Markdown)
  status.json      # Progress state per tracking unit
  meta.json        # Repos and targets lists
  notes.json       # Timestamped notes
```

Files are human-readable and editable. Back up `~/.projects/` or sync it with iCloud/Dropbox/dotfiles to keep it across machines.

## License

MIT
