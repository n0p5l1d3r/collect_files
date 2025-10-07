#!/usr/bin/env bash
# collect_files.sh - collect all files under a parent dir into a single folder
# Usage:
#   ./collect_files.sh -s /path/to/parent -d /path/to/dest [--mode suffix|prefix] [--ext "jpg,png,txt"] [--dry-run]
set -euo pipefail

show_help() {
  cat <<EOF
collect_files.sh - copy all files from a parent directory (recursively) into a single destination folder.

Required:
  -s, --source    Parent directory to scan (recursive)
  -d, --dest      Destination directory to copy files into

Options:
  --mode MODE     Collision mode: "suffix" (default) or "prefix"
                    suffix: if name exists -> file_1.ext, file_2.ext...
                    prefix: use path-based name: subdir_file.ext (minimizes collisions)
  --ext LIST      Comma-separated list of extensions to include (no dots). If omitted, all files copied.
  --dry-run       Print actions but don't copy
  -h, --help      Show this help
EOF
}

# defaults
MODE="suffix"
EXT_FILTER=""
DRYRUN=0
SRC=""
DST=""

# parse args (simple)
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--source) SRC="$2"; shift 2 ;;
    -d|--dest) DST="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --ext) EXT_FILTER="$2"; shift 2 ;;
    --dry-run) DRYRUN=1; shift ;;
    -h|--help) show_help; exit 0 ;;
    *) echo "Unknown arg: $1"; show_help; exit 1 ;;
  esac
done

if [[ -z "$SRC" || -z "$DST" ]]; then
  echo "ERROR: --source and --dest required"
  show_help
  exit 2
fi

# normalize
SRC=$(realpath "$SRC")
DST=$(realpath -m "$DST")
mkdir -p "$DST"

# prepare find expression if ext filter provided
FIND_EXPR=()
if [[ -n "$EXT_FILTER" ]]; then
  IFS=',' read -r -a _exts <<< "$EXT_FILTER"
  expr="("
  for e in "${_exts[@]}"; do
    e_trim=$(echo "$e" | xargs) # trim spaces
    expr+=" -iname '*.${e_trim}' -o"
  done
  expr=${expr% -o}  # drop trailing -o
  expr+=" )"
  # Use eval with constructed expr
  FIND_CMD=(find "$SRC" -type f $expr -print0)
else
  FIND_CMD=(find "$SRC" -type f -print0)
fi

echo "Scanning: $SRC"
echo "Copy destination: $DST"
echo "Mode: $MODE"
[[ -n "$EXT_FILTER" ]] && echo "Extensions filter: $EXT_FILTER"
[[ $DRYRUN -eq 1 ]] && echo "DRY RUN: no files will be copied"

# iterate files safely
# shellcheck disable=SC2068
eval "${FIND_CMD[@]}" | while IFS= read -r -d '' file; do
  # compute basename
  base=$(basename "$file")
  if [[ "$MODE" == "prefix" ]]; then
    # create a path-based safe name: replace leading "$SRC/" and then change slashes to underscores
    rel="${file#$SRC/}"
    safe=$(echo "$rel" | tr '/' '_')
    dest="$DST/$safe"
  else
    # suffix mode: try to copy by basename; if collision occurs append numeric suffix
    name="$base"
    dest="$DST/$name"
    if [[ -e "$dest" ]]; then
      # split name and ext
      if [[ "$name" == *.* ]]; then
        fname="${name%.*}"
        fext=".${name##*.}"
      else
        fname="$name"
        fext=""
      fi
      n=1
      while [[ -e "$DST/${fname}_${n}${fext}" ]]; do ((n++)); done
      dest="$DST/${fname}_${n}${fext}"
    fi
  fi

  if [[ $DRYRUN -eq 1 ]]; then
    printf "DRY: copy %s -> %s\n" "$file" "$dest"
  else
    # ensure dest dir exists (flat layout so DST exists). Use cp -p to preserve timestamps/perm.
    cp -p -- "$file" "$dest"
    # If you want to preserve SELinux context or xattrs, consider: cp -a
    printf "copied: %s -> %s\n" "$file" "$dest"
  fi
done

echo "Done."
