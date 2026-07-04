---
description: latexdiff PDF vs a git revision; keeps only the diff PDF.
argument-hint: [options] <old-git-ref>
---
Generate a diff PDF comparing the current working tree against a git ref using
the project's script.

1. Confirm this is a git repo and that `latexdiff` and `latexmk` are on PATH.
2. Run: `bash scripts/latexdiff-pdf.sh $ARGUMENTS`
3. Report the output path (default `./diff.pdf`).
4. If latexmk fails, re-run the same command with `--keep-aux` and show the
   relevant error lines from the temp `diff.log` whose path is printed.

Options accepted by the script: `-m/--main FILE`, `-o/--out FILE`,
`-e/--engine xelatex|lualatex|pdf`, `-n/--new-ref REF`, `-k/--keep-aux`,
`--no-figures` (skip figure markup), `--no-bib` (skip citation markup).
Examples: `/diffpdf HEAD~1`, `/diffpdf -e pdf -m paper.tex v1-submitted`.
