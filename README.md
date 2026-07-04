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

## Install (optional: a global `tdiff` command)

Symlink the script into a directory on your `PATH` so you can call it from any
project as `tdiff`:

```bash
./install.sh                 # symlinks tdiff into ~/.local/bin
# or manually:
ln -s "$PWD/scripts/latexdiff-pdf.sh" ~/.local/bin/tdiff
```

Make sure `~/.local/bin` is on your `PATH` (it is by default on this machine).
The command name is `tdiff` to avoid colliding with TeX Live's own `texdiff`
tool. Being a symlink, it always tracks the latest version of the repo. After
that, `tdiff` and `scripts/latexdiff-pdf.sh` are interchangeable.

## Usage

```
tdiff [options] <old-git-ref>          # if installed
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
| `--no-figures` | off | don't mark changed figures (`latexdiff --graphics-markup=none`) |
| `--no-bib` | off | don't mark changed citations (`latexdiff --disable-citation-markup`) |
| `-h, --help` | — | print usage and exit |

### Examples

```bash
scripts/latexdiff-pdf.sh HEAD~1                       # since last commit
scripts/latexdiff-pdf.sh -e pdf -m paper.tex v1       # English doc, custom main
scripts/latexdiff-pdf.sh --new-ref HEAD v1-submitted  # diff two committed revs
scripts/latexdiff-pdf.sh --keep-aux HEAD              # keep intermediates to debug
scripts/latexdiff-pdf.sh --no-figures --no-bib HEAD  # don't highlight figure/citation changes
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
  is marked. Use `--no-figures` to skip figure markup and `--no-bib` to skip
  citation markup entirely (the figures and references still compile, they're
  just not highlighted as changed).
- **Keeping intermediates:** run with `--keep-aux`; the temp dir path (with all
  `.tex` / `.aux` / `.log`) is printed and survives.
