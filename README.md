# texdiff

A small, fast tool that produces a **latexdiff PDF** comparing a git revision
against your current working tree — and cleans up every intermediate file,
leaving only the diff PDF.

Every intermediate (`.tex`, `.aux`, `.log`, the extracted old tree, …) lives in
a `mktemp` dir that is removed on exit — even if the compile fails. Exactly one
file, the diff PDF, is copied back into your project.

## Requirements

`latexdiff`, `latexmk`, and `git` on your `PATH` (all ship with TeX Live /
MacTeX). Run the script from **inside your LaTeX project's git repo**.

## Usage

```
scripts/latexdiff-pdf.sh [options] <old-git-ref>
```

`<old-git-ref>` can be a commit hash, tag (`v1.0`), or branch. By default the
**new** side is your working tree, so uncommitted edits are included.

| Flag | Default | Meaning |
|------|---------|---------|
| `-m, --main FILE` | `main.tex` | main LaTeX file |
| `-o, --out FILE` | `diff.pdf` | output PDF path |
| `-e, --engine ENGINE` | `xelatex` | `xelatex` / `lualatex` / `pdf` (pdflatex) |
| `-n, --new-ref REF` | *(working tree)* | diff against a committed ref instead of the working tree |
| `-k, --keep-aux` | off | keep the temp dir (aux/log/tex) and print its path |
| `-h, --help` | — | print usage and exit |

### Examples

```bash
scripts/latexdiff-pdf.sh HEAD~1                       # since last commit
scripts/latexdiff-pdf.sh -e pdf -m paper.tex v1       # English doc, custom main
scripts/latexdiff-pdf.sh --new-ref HEAD v1-submitted  # diff two committed revs
scripts/latexdiff-pdf.sh --keep-aux HEAD              # keep intermediates to debug
```

CJK / KOMA-Script reports should keep the default `xelatex` engine; use
`-e pdf` only for pure-English documents.

## Claude Code slash command

Inside a Claude Code session in your project: `/diffpdf HEAD~1`. See
`.claude/commands/diffpdf.md`.

## Notes

- **Bibliography:** `latexmk` runs biber/bibtex automatically. The old tree is
  added to `BIBINPUTS`, so an old `.bib` that was moved or renamed still
  resolves. latexdiff diffs the `.tex` (so `\cite` commands in the text are
  marked), not the `.bib` entries themselves.
- **Figure source changes:** the old tree is added to `TEXINPUTS`, so figures
  renamed or deleted since the old ref still resolve during compilation instead
  of failing with "file not found." Note that binary image *content* changes
  cannot be visually diffed — only a figure's inclusion / caption / label text
  is marked.
- **Keeping intermediates:** run with `--keep-aux`; the temp dir path (with all
  `.tex` / `.aux` / `.log`) is printed and survives.
