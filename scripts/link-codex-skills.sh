#!/usr/bin/env bash
# Link repository skills into Codex USER scope (~/.agents/skills).
# Codex follows symlinks (Unix) and junctions (Windows) when scanning skill locations.
#
# Usage:
#   ./scripts/link-codex-skills.sh          # link all skills (default)
#   ./scripts/link-codex-skills.sh link     # same as default
#   ./scripts/link-codex-skills.sh unlink   # remove links created by this repo
#   ./scripts/link-codex-skills.sh status   # show link state

set -euo pipefail

readonly CODEX_USER_SKILLS="${CODEX_USER_SKILLS:-$HOME/.agents/skills}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

# ── Platform detection ────────────────────────────────────────────────

is_windows() {
  local os
  os="$(uname -s 2>/dev/null || echo 'Windows')"
  [[ "$os" == *"MINGW"* || "$os" == *"MSYS"* || "$os" == *"CYGWIN"* || -n "${WINDIR:-}" ]]
}

# Convert a Git-Bash/MSYS Unix-style path to a Windows native path.
# /c/Users/... → C:\Users\...
win_path() {
  local p="$1"
  if command -v cygpath &>/dev/null; then
    cygpath -w "$p"
  else
    echo "$p" | sed 's|^/\([a-zA-Z]\)/|\1:\\|' | sed 's|/|\\|g'
  fi
}

# ── Cross-platform link helpers ───────────────────────────────────────
# On Windows, PowerShell queries junction state; Git Bash rm removes them.

is_link() {
  local p="$1"
  if is_windows; then
    local wp out
    wp="$(win_path "$p")"
    out="$(powershell.exe -NoProfile -Command \
      "\$i=Get-Item -LiteralPath '$wp' -Force -EA SilentlyContinue; if(\$i.LinkType){Write-Output 1}")"
    [[ -n "$out" ]]
  else
    [[ -L "$p" ]]
  fi
}

link_points_to_repo() {
  local target="$1"
  local skill_name="$2"
  local expected="$repo_root/$skill_name"

  if is_windows; then
    is_link "$target" || return 1

    local wt we actual
    wt="$(win_path "$target")"
    we="$(win_path "$expected")"
    actual="$(powershell.exe -NoProfile -Command \
      "\$i=Get-Item -LiteralPath '$wt' -Force -EA Stop; Write-Output \$i.Target")"
    [[ -z "$actual" ]] && return 1
    # Normalise: strip trailing slash, compare case-insensitively
    actual="${actual%/}"
    we="${we%/}"
    [[ "${actual,,}" == "${we,,}" ]]
  else
    [[ -L "$target" ]] || return 1
    local actual
    actual="$(cd "$(dirname "$target")" && readlink "$(basename "$target")")" || return 1
    local resolved
    resolved="$(cd "$(dirname "$target")" && cd "$actual" && pwd)" || return 1
    local expected_resolved
    expected_resolved="$(cd "$expected" && pwd)" || return 1
    [[ "$resolved" == "$expected_resolved" ]]
  fi
}

create_link() {
  local src="$1"
  local dest="$2"
  if is_windows; then
    local ws wd
    ws="$(win_path "$src")"
    wd="$(win_path "$dest")"
    powershell.exe -NoProfile -Command \
      "New-Item -ItemType Junction -Path '$wd' -Target '$ws' -Force" >/dev/null
  else
    ln -sfn "$src" "$dest"
  fi
}

remove_link() {
  local p="$1"
  if is_windows; then
    # Git Bash rm handles junctions: removes the reparse point, not the target
    rm -f "$p" 2>/dev/null || true
  else
    rm "$p"
  fi
}

# ── Skill discovery (platform-agnostic) ───────────────────────────────

usage() {
  cat <<'EOF'
Link skills from this repository into Codex global skill directory.

Commands:
  link    Create symlinks in ~/.agents/skills (default)
  unlink  Remove symlinks that point into this repository
  status  Show which repo skills are linked

Environment:
  CODEX_USER_SKILLS   Target directory (default: ~/.agents/skills)

On Windows, directory junctions are used instead of symlinks (no admin
required). Codex follows both.

After linking, restart Codex if new skills do not appear immediately.
EOF
}

is_repo_skill() {
  local name="$1"
  [[ "$name" != .* ]] && [[ -f "$repo_root/$name/SKILL.md" ]]
}

list_repo_skills() {
  local name
  for entry in "$repo_root"/*; do
    [[ -d "$entry" ]] || continue
    name="$(basename "$entry")"
    if is_repo_skill "$name"; then
      printf '%s\n' "$name"
    fi
  done | sort
}

# ── Commands ──────────────────────────────────────────────────────────

cmd_link() {
  local skill
  local created=0
  local updated=0
  local skipped=0

  mkdir -p "$CODEX_USER_SKILLS"

  while IFS= read -r skill; do
    [[ -n "$skill" ]] || continue
    local src="$repo_root/$skill"
    local dest="$CODEX_USER_SKILLS/$skill"

    if [[ -e "$dest" ]] || is_link "$dest"; then
      if link_points_to_repo "$dest" "$skill"; then
        echo "skip  $skill (already linked)"
        skipped=$((skipped + 1))
        continue
      fi
      if is_link "$dest"; then
        echo "update $skill (replacing existing link)"
        remove_link "$dest"
        updated=$((updated + 1))
      else
        echo "error $skill: $dest exists and is not a link to this repo" >&2
        exit 1
      fi
    fi

    create_link "$src" "$dest"
    echo "link  $skill -> $dest"
    created=$((created + 1))
  done < <(list_repo_skills)

  echo ""
  echo "Done. linked=$created updated=$updated skipped=$skipped"
  echo "Codex USER skills dir: $CODEX_USER_SKILLS"
  echo "Restart Codex if skills do not show up."
}

cmd_unlink() {
  local skill
  local removed=0
  local skipped=0

  while IFS= read -r skill; do
    [[ -n "$skill" ]] || continue
    local dest="$CODEX_USER_SKILLS/$skill"

    if [[ ! -e "$dest" ]] && ! is_link "$dest"; then
      echo "skip  $skill (not present)"
      skipped=$((skipped + 1))
      continue
    fi

    if link_points_to_repo "$dest" "$skill"; then
      remove_link "$dest"
      echo "unlink $skill"
      removed=$((removed + 1))
    else
      echo "skip  $skill (not managed by this repo)"
      skipped=$((skipped + 1))
    fi
  done < <(list_repo_skills)

  echo ""
  echo "Done. removed=$removed skipped=$skipped"
}

cmd_status() {
  local skill
  local linked=0
  local missing=0

  echo "Repository: $repo_root"
  echo "Codex dir:  $CODEX_USER_SKILLS"
  echo ""

  while IFS= read -r skill; do
    [[ -n "$skill" ]] || continue
    local dest="$CODEX_USER_SKILLS/$skill"

    if link_points_to_repo "$dest" "$skill"; then
      echo "linked   $skill -> $dest"
      linked=$((linked + 1))
    else
      echo "missing  $skill"
      missing=$((missing + 1))
    fi
  done < <(list_repo_skills)

  echo ""
  echo "linked=$linked missing=$missing"
}

# ── Entry point ───────────────────────────────────────────────────────

main() {
  local cmd="${1:-link}"

  case "$cmd" in
    -h|--help|help)
      usage
      ;;
    link)
      cmd_link
      ;;
    unlink)
      cmd_unlink
      ;;
    status)
      cmd_status
      ;;
    *)
      echo "Unknown command: $cmd" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
