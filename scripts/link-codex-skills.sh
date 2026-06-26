#!/usr/bin/env bash
# Link repository skills into Codex USER scope (~/.agents/skills).
# Codex follows symlinks when scanning skill locations.
#
# Usage:
#   ./scripts/link-codex-skills.sh          # link all skills (default)
#   ./scripts/link-codex-skills.sh link     # same as default
#   ./scripts/link-codex-skills.sh unlink   # remove symlinks created by this repo
#   ./scripts/link-codex-skills.sh status   # show link state

set -euo pipefail

readonly CODEX_USER_SKILLS="${CODEX_USER_SKILLS:-$HOME/.agents/skills}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

usage() {
  cat <<'EOF'
Link skills from this repository into Codex global skill directory.

Commands:
  link    Create symlinks in ~/.agents/skills (default)
  unlink  Remove symlinks that point into this repository
  status  Show which repo skills are linked

Environment:
  CODEX_USER_SKILLS   Target directory (default: ~/.agents/skills)

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

link_points_to_repo() {
  local target="$1"
  local skill_name="$2"
  local expected="$repo_root/$skill_name"

  [[ -L "$target" ]] || return 1
  local actual
  actual="$(cd "$(dirname "$target")" && readlink "$(basename "$target")")"
  [[ "$(cd "$(dirname "$actual")" 2>/dev/null && pwd)/$(basename "$actual")" == "$expected" ]] || \
    [[ "$actual" == "$expected" ]]
}

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

    if [[ -e "$dest" || -L "$dest" ]]; then
      if link_points_to_repo "$dest" "$skill"; then
        echo "skip  $skill (already linked)"
        skipped=$((skipped + 1))
        continue
      fi
      if [[ -L "$dest" ]]; then
        echo "update $skill (replacing existing symlink)"
        rm "$dest"
        updated=$((updated + 1))
      else
        echo "error $skill: $dest exists and is not a symlink to this repo" >&2
        exit 1
      fi
    fi

    ln -sfn "$src" "$dest"
    if [[ $updated -eq 0 || ! -e "$dest" ]]; then
      echo "link  $skill -> $dest"
      created=$((created + 1))
    fi
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

    if [[ ! -e "$dest" && ! -L "$dest" ]]; then
      echo "skip  $skill (not present)"
      skipped=$((skipped + 1))
      continue
    fi

    if link_points_to_repo "$dest" "$skill"; then
      rm "$dest"
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
