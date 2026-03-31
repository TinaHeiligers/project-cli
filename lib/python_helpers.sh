#!/usr/bin/env bash
# python_helpers.sh — Shared Python code for notes migration and loading

# Returns Python code that defines load_notes(path) and save_notes(path, data).
# load_notes handles migration: adds IDs to any notes missing them, sets _next_id.
# Usage in heredoc: eval "$(notes_python_preamble)"
NOTES_PYTHON_PREAMBLE='
import json, os, datetime

def load_notes(nf):
    """Load notes.json, migrating to add IDs if needed."""
    data = json.load(open(nf)) if os.path.exists(nf) else {}
    next_id = data.get("_next_id", 1)
    migrated = False
    for key, notes in data.items():
        if key.startswith("_"):
            continue
        if not isinstance(notes, list):
            continue
        for note in notes:
            if "id" not in note:
                note["id"] = next_id
                next_id += 1
                migrated = True
    data["_next_id"] = next_id
    if migrated:
        save_notes(nf, data)
    return data

def save_notes(nf, data):
    """Save notes.json preserving _next_id."""
    json.dump(data, open(nf, "w"), indent=2)

def next_note_id(data):
    """Get and increment the next note ID."""
    nid = data.get("_next_id", 1)
    data["_next_id"] = nid + 1
    return nid
'
