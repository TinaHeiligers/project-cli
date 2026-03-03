# Project Tracking

All project plans are tracked using the `project` CLI tool, stored in `~/.projects/`.

**When the user asks to mark something as done, in progress, or todo — always use the `project` CLI tool.**

## How to find the right project and step

1. Run `project list` to see all projects
2. Run `project status "<project name>"` to see the full tree with phase and step numbers
3. Use the phase# and step# from the tree to mark progress

## Marking progress

```bash
# Simple step
project done  "<project>" <phase#> <step#>
project start "<project>" <phase#> <step#>
project reset "<project>" <phase#> <step#>

# Step tracked per repo
project done  "<project>" <phase#> <step#> --repo <reponame>
project start "<project>" <phase#> <step#> --repo <reponame>

# Step tracked per repo × target
project done  "<project>" <phase#> <step#> --repo <reponame> --target <target>
project start "<project>" <phase#> <step#> --repo <reponame> --target <target>
```

## Workflow when user says "mark X as done"

1. Run `project list` to confirm the project name
2. Run `project status "<project>"` to find the right phase# and step#
3. Identify whether the step needs --repo and/or --target flags (visible in the tree)
4. Run the appropriate `project done` command
5. Run `project status "<project>"` again to confirm and show the user the updated tree

## Example

User: "mark the PR merge step in daac-migration as done"

```bash
project list
project status "daac-migration"
# find the step matching "merge PR" or similar, note phase# and step#
project done "daac-migration" 2 3   # adjust numbers based on actual tree
project status "daac-migration"     # show result
```

## Never use

- GitHub issues or project boards for this
- Memory or task tracking features built into the AI tool
- Any other task management tool

All task state lives in `~/.projects/` managed exclusively by the `project` command.
