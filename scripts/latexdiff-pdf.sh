#!/usr/bin/env bash
# Generate a latexdiff PDF between a git revision and the working tree (or
# another git ref). Every intermediate lives in a temp dir removed on exit —
# only the resulting diff PDF is left in the project.
set -euo pipefail

PROG="$(basename "$0")"

usage() {
  cat <<EOF
Usage: $PROG [options] <old-git-ref>

Generate a latexdiff PDF comparing <old-git-ref> against the current working
tree (default) or another ref. Only the final PDF is kept; all aux/log/tex
intermediates are removed on exit.

Options:
  -m, --main FILE     Main LaTeX file          (default: main.tex)
  -o, --out FILE      Output PDF path           (default: diff.pdf)
  -e, --engine ENGINE Compile engine: xelatex | lualatex | pdf (default: xelatex)
  -n, --new-ref REF   Diff against a committed ref instead of the working tree
  -k, --keep-aux      Keep the temp dir (aux/log/tex) and print its path
      --no-figures    Don't mark changed figures (latexdiff --graphics-markup=none)
      --no-bib        Don't mark changed citations (latexdiff --disable-citation-markup)
  -h, --help          Show this help and exit

Examples:
  $PROG HEAD~1
  $PROG -e pdf -m paper.tex v1-submitted
  $PROG --new-ref HEAD v1-submitted
  $PROG --keep-aux HEAD
EOF
}

die() { echo "$PROG: $*" >&2; exit 1; }

# --- defaults ---------------------------------------------------------------
MAIN="main.tex"
OUT="diff.pdf"
ENGINE="xelatex"
NEWREF=""
KEEP=""
OLDREF=""
LATEXDIFF_OPTS=(--flatten)

# --- flag parsing -----------------------------------------------------------
POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    -m|--main)     MAIN="${2:?--main needs a value}";     shift 2 ;;
    --main=*)      MAIN="${1#*=}";                        shift ;;
    -o|--out)      OUT="${2:?--out needs a value}";       shift 2 ;;
    --out=*)       OUT="${1#*=}";                         shift ;;
    -e|--engine)   ENGINE="${2:?--engine needs a value}"; shift 2 ;;
    --engine=*)    ENGINE="${1#*=}";                      shift ;;
    -n|--new-ref)  NEWREF="${2:?--new-ref needs a value}"; shift 2 ;;
    --new-ref=*)   NEWREF="${1#*=}";                      shift ;;
    -k|--keep-aux) KEEP=1;                                shift ;;
    --no-figures)  LATEXDIFF_OPTS+=(--graphics-markup=none);    shift ;;
    --no-bib)      LATEXDIFF_OPTS+=(--disable-citation-markup); shift ;;
    -h|--help)     usage; exit 0 ;;
    --)            shift; while [ $# -gt 0 ]; do POSITIONAL+=("$1"); shift; done ;;
    -*)            die "unknown option: $1 (see --help)" ;;
    *)             POSITIONAL+=("$1"); shift ;;
  esac
done

[ "${#POSITIONAL[@]}" -eq 0 ] && { usage; die "missing required <old-git-ref>"; }
[ "${#POSITIONAL[@]}" -gt 1 ] && die "too many arguments: ${POSITIONAL[*]}"
OLDREF="${POSITIONAL[0]}"

# Map engine name to the latexmk flag.
case "$ENGINE" in
  xelatex)  ENGINE_FLAG="-xelatex" ;;
  lualatex) ENGINE_FLAG="-lualatex" ;;
  pdf)      ENGINE_FLAG="-pdf" ;;
  *)        die "invalid engine: $ENGINE (use xelatex, lualatex, or pdf)" ;;
esac

# --- preflight --------------------------------------------------------------
command -v latexdiff >/dev/null || die "latexdiff not found on PATH"
command -v latexmk   >/dev/null || die "latexmk not found on PATH"
command -v git       >/dev/null || die "git not found on PATH"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "not inside a git work tree (run from your LaTeX project repo)"
[ -f "$MAIN" ] || die "main file not found: $MAIN"

# --- work in a temp dir that is wiped on exit -------------------------------
TMP="$(mktemp -d)"
trap '[ -n "$KEEP" ] || rm -rf "$TMP"' EXIT

# 1. Materialise the OLD revision as a full tree (so \input subfiles exist too).
mkdir -p "$TMP/old"
git archive "$OLDREF" | tar -x -C "$TMP/old" \
  || die "failed to archive old ref: $OLDREF"
[ -f "$TMP/old/$MAIN" ] || die "main file '$MAIN' not present at ref '$OLDREF'"

# 2. NEW side: working tree by default, or another ref if requested.
if [ -n "$NEWREF" ]; then
  mkdir -p "$TMP/new"
  git archive "$NEWREF" | tar -x -C "$TMP/new" \
    || die "failed to archive new ref: $NEWREF"
  [ -f "$TMP/new/$MAIN" ] || die "main file '$MAIN' not present at ref '$NEWREF'"
  NEWMAIN="$TMP/new/$MAIN"
else
  NEWMAIN="$MAIN"
fi

# 3. latexdiff, flattening \input/\include on both sides. --no-figures /
#    --no-bib append options that suppress figure / citation markup.
latexdiff "${LATEXDIFF_OPTS[@]}" "$TMP/old/$MAIN" "$NEWMAIN" > "$TMP/diff.tex"

# 4. Compile with latexmk. cwd stays the project root so current figures/.bib/
#    .sty resolve; the archived old tree is prepended to the search paths so old
#    figures/.bib (renamed or deleted since the ref) also resolve. Output is
#    pinned inside TMP.
TEXINPUTS="$TMP/old//:${PWD}//:${TEXINPUTS:-}" \
BIBINPUTS="$TMP/old//:${PWD}//:${BIBINPUTS:-}" \
latexmk "$ENGINE_FLAG" -interaction=nonstopmode -halt-on-error \
        -outdir="$TMP" "$TMP/diff.tex" \
  || die "latexmk failed; re-run with --keep-aux and inspect $TMP/diff.log"

# 5. Keep ONLY the PDF.
[ -f "$TMP/diff.pdf" ] || die "no PDF produced (see $TMP/diff.log)"
cp "$TMP/diff.pdf" "./$OUT"
echo "wrote ./$OUT"
[ -n "$KEEP" ] && echo "kept intermediates in $TMP"
exit 0
