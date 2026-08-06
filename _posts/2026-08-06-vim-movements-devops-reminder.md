---
title: Vim Movements for DevOps — My Personal Cheat Sheet
mermaid: true
categories: [homelab]
tags: [vim, neovim, devops, terminal, linux, cheat-sheet]
---

I've been using Vim (and Neovim) for years now. Not because I'm some purist who thinks you're not a real engineer if you don't use it — but because when you spend half your day SSH'd into servers, editing configs, poking at YAML manifests, and grepping logs, knowing how to move fast in a terminal editor saves your sanity.

This post is my personal reminder. I keep forgetting some of the less common movements, and instead of googling "how to jump to matching bracket vim" for the 47th time, I decided to write it all down in one place.

It's optimized for **DevOps work** — meaning I focus on the movements and commands you actually need when editing Kubernetes manifests, Helm values, Terraform files, Docker Compose configs, shell scripts, and scrolling through massive log files. No fluff, no "how to exit vim" jokes (we've all heard them).

If you want a more beginner-friendly intro, check out [Jake Wiesler's essential vim movements](https://www.jakewiesler.com/blog/essential-vim-movements) — that post got me started. This one is the expanded version, with all the DevOps-specific stuff added.

---

## Table of Contents

- [The absolute basics — hjkl](#the-absolute-basics--hjkl)
- [Word movements](#word-movements)
- [Line jumps](#line-jumps)
- [Screen scrolling](#screen-scrolling)
- [File navigation](#file-navigation)
- [Search and replace](#search-and-replace)
- [Marks and jumps](#marks-and-jumps)
- [Text objects — the DevOps superpower](#text-objects--the-devops-superpower)
- [Bracket and tag matching](#bracket-and-tag-matching)
- [Windows, buffers, and tabs](#windows-buffers-and-tabs)
- [Quickfix and location lists](#quickfix-and-location-lists)
- [Folds — taming massive config files](#folds--taming-massive-config-files)
- [Registers and macros](#registers-and-macros)
- [DevOps-specific workflows](#devops-specific-workflows)
- [Essential .vimrc / init.lua settings](#essential-vimrc--initlua-settings)
- [Cheat sheet summary](#cheat-sheet-summary)

---

## The absolute basics — hjkl

Yeah, I know. But let's get it out of the way so the rest makes sense.

| Key | Action |
|-----|--------|
| `h` | Move left |
| `j` | Move down |
| `k` | Move up |
| `l` | Move right |

Think of them as flattened arrow keys. `j` has a descender (hooks down), `k` points up. That's how I remember it 😅

You can prefix any of these with a count:

- `5j` — move down 5 lines
- `10l` — move right 10 characters

---

## Word movements

When you're editing a 500-line Helm `values.yaml`, `hjkl` alone will make you lose your mind. Word movements are where Vim starts to shine.

| Key | Action |
|-----|--------|
| `w` | Forward to start of next **word** |
| `W` | Forward to start of next **WORD** (whitespace-delimited) |
| `b` | Backward to start of previous word |
| `B` | Backward to start of previous WORD |
| `e` | Forward to end of current word |
| `E` | Forward to end of current WORD |
| `ge` | Backward to end of previous word |

**Word vs WORD:** A "word" in Vim is a sequence of letters, digits, and underscores. A "WORD" is anything separated by whitespace. In DevOps, this matters a lot:

```
spec.containers[0].image
```

- `w` jumps between `spec`, `containers`, `0`, `image` (stops at punctuation)
- `W` jumps to... well, there's no whitespace here, so `W` jumps to end of line or next whitespace

When editing YAML or dotfiles, `w` is usually more useful. When editing shell scripts with long pipe chains, `W` is your friend.

---

## Line jumps

| Key | Action |
|-----|--------|
| `0` | Go to first column (absolute beginning) |
| `^` | Go to first non-blank character |
| `$` | Go to end of line |
| `g_` | Go to last non-blank character |
| `f{char}` | Find next occurrence of {char} on current line |
| `F{char}` | Find previous occurrence of {char} on current line |
| `t{char}` | Till next occurrence of {char} (cursor stops before it) |
| `T{char}` | Till previous occurrence of {char} |
| `;` | Repeat last f/F/t/T |
| `,` | Repeat last f/F/t/T in opposite direction |

The `f` / `t` family is **insanely useful** for DevOps. Editing a long `kubectl` command? `t/` gets you right before the next `/` in a path. `f:` jumps you to the next colon in a YAML key-value pair.

```yaml
# You're at the start of this line:
    image: registry.example.com/myapp:1.2.3
# f: jumps to the first colon
# ; jumps to the next colon (the one before the tag)
# t: jumps to just before it, so you can change the tag
```

### Insert-mode shortcuts at line boundaries

| Key | Action |
|-----|--------|
| `I` | Go to first non-blank character, enter INSERT mode |
| `A` | Go to end of line, enter INSERT mode |
| `o` | Open new line below, enter INSERT mode |
| `O` | Open new line above, enter INSERT mode |

`A` is probably my most-used key in config editing. Need to append a flag to a command? `A` → type → `Esc`. Done.

---

## Screen scrolling

| Key | Action |
|-----|--------|
| `Ctrl-d` | Scroll half page down |
| `Ctrl-u` | Scroll half page up |
| `Ctrl-f` | Scroll full page down |
| `Ctrl-b` | Scroll full page up |
| `Ctrl-e` | Scroll one line down (cursor stays) |
| `Ctrl-y` | Scroll one line up (cursor stays) |
| `zz` | Center cursor on screen |
| `zt` | Top-align cursor on screen |
| `zb` | Bottom-align cursor on screen |
| `H` | Jump to top of screen |
| `M` | Jump to middle of screen |
| `L` | Jump to bottom of screen |

`zz` is gold. When you're reading a long log file and the cursor drifted to the bottom of the screen, `zz` re-centers you instantly. No more squinting at the last line.

When tailing logs with `:set wrap` off (which you should do for logs), `Ctrl-d` and `Ctrl-u` let you scan through output quickly without losing your place.

---

## File navigation

| Key | Action |
|-----|--------|
| `gg` | Jump to first line |
| `G` | Jump to last line |
| `{n}G` | Jump to line {n} |
| `{n}gg` | Jump to line {n} (alternative) |
| `Ctrl-o` | Jump to previous cursor position |
| `Ctrl-i` | Jump to next cursor position (forward in jump list) |
| `Ctrl-]` | Jump to tag/definition (ctags / LSP) |
| `gd` | Go to local definition |
| `gD` | Go to global definition |
| `%` | Jump to matching bracket/paren/brace |
| `{` | Jump to previous empty line |
| `}` | Jump to next empty line |

`Ctrl-o` / `Ctrl-i` are the **undo/redo of cursor movement**. You jumped to a definition, now jump back with `Ctrl-o`. This is essential when you're navigating a large repo and following references across files.

`{` and `}` are underrated. In a YAML file with blank lines between resources, `}` jumps you to the next resource block. In a shell script, it jumps between functions.

---

## Search and replace

| Key | Action |
|-----|--------|
| `/{pattern}` | Search forward |
| `?{pattern}` | Search backward |
| `n` | Next match |
| `N` | Previous match |
| `*` | Search forward for word under cursor |
| `#` | Search backward for word under cursor |
| `g*` | Search forward (partial match) |
| `g#` | Search backward (partial match) |

`*` is my go-to for finding all occurrences of a variable name, a service name, or a Kubernetes label. Put the cursor on `my-app` and hit `*` — instant search for every reference.

### Search and replace

```vim
" Replace first occurrence on current line
:s/old/new/

" Replace all occurrences on current line
:s/old/new/g

" Replace in entire file, with confirmation
:%s/old/new/gc

" Replace in selected lines (visual mode, then :s)
:'<,'>s/old/new/g

" Replace in range
:20,30s/old/new/g

" Use very-magic mode (less escaping for regex)
:%s/\v(old_pattern)/new/g
```

The `c` flag gives you a prompt for each match — press `y` to replace, `n` to skip. Essential when you're renaming a service and want to make sure you don't nuke something you didn't mean to.

{: .prompt-tip }
`%s/\v` with very-magic mode (`\v`) is a lifesaver when dealing with regex-heavy patterns. No more `\(.*\)` — just `(.*)`. Your YAML/regex combos will thank you.

### DevOps search patterns

```vim
" Find all image: lines in a K8s manifest
/image:

" Find all containers with a specific registry
/registry\.example\.com

" Find TODO/FIXME comments
/TODO\|FIXME

" Find all uncommented replicas
/^replicas:

" Find lines with trailing whitespace (good for cleanup)
/\s$
```

---

## Marks and jumps

Marks let you bookmark positions in a file and jump back to them. In DevOps, this is useful when you're comparing two sections of a large config, or when you need to jump between a resource definition and its reference.

| Key | Action |
|-----|--------|
| `m{a-z}` | Set mark {a-z} (local to buffer) |
| `m{A-Z}` | Set mark {A-Z} (global, across files) |
| `'{a-z}` | Jump to mark {a-z} (first non-blank) |
| `` `{a-z} `` | Jump to mark {a-z} (exact column) |
| `'` | Jump to last line you were on |
| `` ` `` | Jump to last position (exact column) |
| `:marks` | List all marks |
| `:delm {a}` | Delete mark {a} |

My workflow: when I'm editing a Terraform file and need to jump to a variable definition, I set a mark `ma` where I am, jump to the variable, copy the reference, then `'a` to get back. Much faster than `Ctrl-o` when you know you'll be bouncing between two spots.

---

## Text objects — the DevOps superpower

This is where Vim goes from "weird editor" to "why would I use anything else." Text objects let you operate on semantic chunks of text — words, sentences, paragraphs, brackets, quotes, tags — with a single keystroke.

The general pattern is:

```
{operator}{a|i}{text-object}
```

- `a` = "around" (includes delimiters)
- `i` = "inside" (excludes delimiters)

### Common text objects

| Key | Action |
|-----|--------|
| `aw` | Around word |
| `iw` | Inside word |
| `as` | Around sentence |
| `is` | Inside sentence |
| `ap` | Around paragraph |
| `ip` | Inside paragraph |
| `ab` | Around brackets `()` |
| `ib` | Inside brackets `()` |
| `aB` | Around braces `{}` |
| `iB` | Inside braces `{}` |
| `a[` | Around brackets `[]` |
| `i[` | Inside brackets `[]` |
| `a'` | Around single quotes |
| `i'` | Inside single quotes |
| `a"` | Around double quotes |
| `i"` | Inside double quotes |
| `at` | Around HTML/XML tags |
| `it` | Inside HTML/XML tags |

### Operators that combine with text objects

| Key | Action |
|-----|--------|
| `d` | Delete |
| `c` | Change (delete + insert) |
| `y` | Yank (copy) |
| `v` | Visual select |
| `>` | Indent |
| `<` | Unindent |
| `=` | Auto-indent |

### DevOps examples

```yaml
# You're inside this block:
containers:
  - name: my-app
    image: registry.example.com/my-app:1.2.3
    ports:
      - containerPort: 8080
```

- `ci"` — change the image tag inside the quotes (`1.2.3` → type new tag)
- `daB` — delete the entire `{}` block (if it were JSON)
- `yi'` — yank the content inside single quotes
- `vit` — select inside the XML/HTML tag (useful for Ansible templates)

When you're editing a Helm template with `{{ }}` delimiters, text objects let you grab the whole expression in one shot. No more counting characters.

{: .prompt-tip }
Text objects work with **any operator**. `>ib` indents everything inside `()`. `=aB` auto-indents everything inside `{}`. `vi"` selects everything inside `""`. Once this clicks, you'll never go back to manual selection.

---

## Bracket and tag matching

| Key | Action |
|-----|--------|
| `%` | Jump to matching bracket/brace/paren |
| `[{` | Jump to previous unmatched `{` |
| `]}` | Jump to next unmatched `}` |
| `[(` | Jump to previous unmatched `(` |
| `])` | Jump to next unmatched `)` |
| `[/` | Jump to previous unmatched `/*` (comment start) |
| `]/` | Jump to next unmatched `*/` (comment end) |

`%` is essential when you're deep in nested JSON (hello, CloudFormation templates) or in a Terraform block with 5 levels of nesting. Put the cursor on any `{` and `%` takes you to its matching `}`. Hit `%` again to bounce back.

---

## Windows, buffers, and tabs

When you're comparing a config against its template, or editing multiple files at once, you need splits.

### Windows (splits)

| Key | Action |
|-----|--------|
| `:sp {file}` | Horizontal split, open {file} |
| `:vsp {file}` | Vertical split, open {file} |
| `Ctrl-w h` | Move to window left |
| `Ctrl-w j` | Move to window down |
| `Ctrl-w k` | Move to window up |
| `Ctrl-w l` | Move to window right |
| `Ctrl-w w` | Cycle windows |
| `Ctrl-w =` | Equal-size windows |
| `Ctrl-w _` | Maximize current window height |
| `Ctrl-w |` | Maximize current window width |
| `Ctrl-w c` | Close window |
| `Ctrl-w o` | Close all but current |

### Buffers

| Key | Action |
|-----|--------|
| `:e {file}` | Open file in current buffer |
| `:bn` | Next buffer |
| `:bp` | Previous buffer |
| `:bd` | Delete buffer (close file) |
| `:ls` | List all buffers |
| `Ctrl-^` | Toggle between current and alternate buffer |

`Ctrl-^` (that's `Ctrl` + `6` on most keyboards) is my secret weapon. It toggles between the last two files you were editing. No need to type `:bn` / `:bp` when you're just bouncing between two configs.

### Tabs

| Key | Action |
|-----|--------|
| `:tabnew {file}` | Open {file} in a new tab |
| `gt` | Next tab |
| `gT` | Previous tab |
| `{n}gt` | Go to tab {n} |
| `:tabc` | Close current tab |
| `:tabo` | Close all but current |

I use tabs for "workspaces" — one tab for the Helm chart, one for the values, one for the rendered output. Splits within each tab for the actual editing.

---

## Quickfix and location lists

This is where Vim becomes a proper IDE for DevOps. When you run `:make`, `:grep`, or an LSP diagnostic, results land in the quickfix list. You can jump between errors without leaving your keyboard.

| Key | Action |
|-----|--------|
| `:copen` | Open quickfix list |
| `:cclose` | Close quickfix list |
| `:cnext` / `cn` | Next error |
| `:cprev` / `cp` | Previous error |
| `:cfirst` | First error |
| `:clast` | Last error |
| `:cnf` | Next file in quickfix |
| `:cfile {file}` | Load error file |
| `:lgrep {pattern} {files}` | Populate location list |
| `:lopen` | Open location list |
| `:lnext` / `:lprev` | Navigate location list |

### DevOps use cases

```vim
" Grep for a pattern and populate quickfix
:grep "image:" *.yaml
:copen

" In Neovim with LSP:
" gd — go to definition
" gr — references
" K — hover docs
" ]d / [d — next/prev diagnostic

" Run kubectl dry-run and capture output
:make kubectl apply --dry-run=client -f %

" Terraform validate
:make terraform validate
```

{: .prompt-info }
In Neovim, the built-in LSP client + `telescope.nvim` for fuzzy finding is a game-changer for DevOps. You get go-to-definition, references, and diagnostics for YAML, Terraform, and even Helm templates with the right LSP servers.

---

## Folds — taming massive config files

When you open a 2000-line `values.yaml`, folds are how you stay sane. They let you collapse sections you're not working on.

| Key | Action |
|-----|--------|
| `zf{motion}` | Create fold |
| `zd` | Delete fold |
| `zo` | Open fold |
| `zc` | Close fold |
| `za` | Toggle fold |
| `zr` | Open all folds (reduce) |
| `zm` | Close all folds (more) |
| `zR` | Open all folds completely |
| `zM` | Close all folds completely |
| `zj` | Next fold |
| `zk` | Previous fold |

### Fold methods

```vim
" Indent-based folding (great for YAML!)
:set foldmethod=indent
:set foldlevel=2

" Marker-based (uses {{{ }}} markers)
:set foldmethod=marker

" Syntax-based
:set foldmethod=syntax

" Manual
:set foldmethod=manual
```

For YAML files, `foldmethod=indent` with `foldlevel=1` is my go-to. You see the top-level keys, and everything below is collapsed. Expand what you need, ignore the rest.

For shell scripts, `foldmethod=marker` works well — put `# {{{` and `# }}}` around sections you want to fold.

---

## Registers and macros

### Registers

Registers are Vim's clipboard system — but on steroids. You have 26 named registers (a-z), plus special ones.

| Key | Action |
|-----|--------|
| `"{a-z}y{motion}` | Yank into register {a-z} |
| `"{a-z}p` | Paste from register {a-z} |
| `"{A-Z}y{motion}` | Append to register {a-z} |
| `"+y` | Yank to system clipboard |
| `"+p` | Paste from system clipboard |
| `"*y` | Yank to primary selection (X11) |
| `"_d` | Delete to black hole register (don't overwrite default register) |
| `:reg` | List all registers |

`"+y` is how you copy from Vim to your system clipboard. Essential when you need to paste a config snippet into a Slack message or a GitHub issue.

`"_d` is the "delete without clobbering my yank register" command. When you want to delete some text but you've got something important in your default register, use `_` as the black hole.

### Macros

Macros let you record a sequence of keystrokes and replay them. For repetitive DevOps edits (like updating image tags across 20 services), this is a lifesaver.

| Key | Action |
|-----|--------|
| `q{a-z}` | Start recording into register {a-z} |
| `q` | Stop recording |
| `@{a-z}` | Play back macro {a-z} |
| `@@` | Play back last macro |
| `{n}@{a-z}` | Play back macro {a-z} {n} times |
| `:normal @a` | Run macro `a` on every line in visual selection |

### DevOps macro example

Scenario: You have 20 service blocks in a `docker-compose.yml`, and you need to update the image tag from `:latest` to `:1.2.3` on each one.

1. Put cursor on first `image:` line
2. `qa` — start recording into register `a`
3. `f:` — find the colon in `image:`
4. `f:` — find the next colon (the tag separator)
5. `cw1.2.3` — change the tag to `1.2.3`
6. `Esc` — back to normal mode
7. `/image:` — search for next `image:` line
8. `Enter` — confirm search
9. `q` — stop recording
10. `19@a` — replay the macro 19 more times

Done. 20 image tags updated in about 5 seconds. 😎

---

## DevOps-specific workflows

Here are some real-world DevOps workflows where knowing these movements makes a massive difference.

### Editing a Kubernetes manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: registry.example.com/my-app:1.2.3
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
```

Workflow to change the image tag:
1. `/image:` — find the image line
2. `f:` — jump to the colon after the registry path
3. `f:` — jump to the colon before the tag
4. `cw1.2.4` — change tag
5. `Esc` — done

Workflow to bump replicas:
1. `/replicas` — find replicas
2. `f ` — find the space after the colon
3. `cw5` — change to 5
4. `Esc` — done

### Comparing two files side by side

```vim
" Open first file
:e values.yaml

" Open second file in a vertical split
:vsp values-production.yaml

" Set scrollbind so both scroll together
:set scrollbind
" (in the other window)
:set scrollbind
```

Now when you scroll in one window, both scroll together. Perfect for comparing dev vs prod values.

### Bulk-editing Helm values

```vim
" Open the values file
:e values.yaml

" Search for all replicas fields
/replicas:

" Change to 5
cw5

" Find next and repeat
n
.
n
.
n
.
```

The `.` command repeats the last change. So after you do `cw5` once, `n` (next search result) followed by `.` (repeat change) lets you blast through the file in seconds.

### Editing a Terraform file

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  count         = 3

  tags = {
    Name        = "web"
    Environment = "production"
  }
}
```

- `ci"` — change the AMI ID inside the quotes
- `ci'` — change a value inside single quotes
- `vaB` — select the entire resource block (everything inside `{}`)
- `=aB` — auto-indent the entire block

### Shell script editing

```bash
#!/bin/bash
set -euo pipefail

IMAGE_TAG="${1:-latest}"
REGISTRY="${REGISTRY:-docker.io}"

docker build -t "${REGISTRY}/my-app:${IMAGE_TAG}" .
docker push "${REGISTRY}/my-app:${IMAGE_TAG}"
```

- `f}` — jump to the end of the `${}` variable
- `ci}` — change the variable name inside `${}`
- `W` — jump between the long pipe-chained commands
- `}` — jump between function blocks (on blank lines)

### Log file analysis

```vim
" Open a log file with wrap disabled
:e /var/log/syslog
:set nowrap

" Search for ERROR
/ERROR

" Jump to next/prev match
n / N

" Delete all lines that DON'T contain ERROR (keep only errors)
:v/ERROR/d

" Or the reverse — delete all ERROR lines
:g/ERROR/d

" Count occurrences
:%s/ERROR//n
```

The `:v/pattern/d` command is one of my favorites for log analysis. It deletes everything that DOESN'T match, leaving only the lines you care about. Just make sure you're working on a copy 😅

---

## Essential .vimrc / init.lua settings

These are the settings I consider mandatory for DevOps work. They make Vim usable for long editing sessions.

### Minimal .vimrc (works in both Vim and Neovim)

```vim
" --- Line numbers ---
set number
set relativenumber

" --- Scrolling ---
set scrolloff=8

" --- Search ---
set incsearch
set nohlsearch
set ignorecase
set smartcase

" --- Indentation ---
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent

" --- Display ---
set wrap
set linebreak
set showmatch
set cursorline
set signcolumn=yes

" --- Split behavior ---
set splitright
set splitbelow

" --- File handling ---
set hidden
set autoread
set swapfile
set undofile
set undodir=~/.vim/undodir

" --- Clipboard (system integration) ---
set clipboard=unnamedplus

" --- Wildmenu (better command-line completion) ---
set wildmenu
set wildmode=longest:full,full

" --- Folding ---
set foldmethod=indent
set foldlevel=2
```

### Neovim-specific extras (init.lua)

```lua
-- Space as leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Exit terminal mode easily
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>')

-- Quick save
vim.keymap.set('n', '<leader>w', ':w<CR>')

-- Close buffer
vim.keymap.set('n', '<leader>q', ':bd<CR>')

-- Split navigation without Ctrl-w prefix
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- Quick resize
vim.keymap.set('n', '<leader>=', '<C-w>=')
vim.keymap.set('n', '<leader>-', '<C-w>_')

-- Clear search highlight
vim.keymap.set('n', '<leader>nh', ':nohlsearch<CR>')

-- Yank to system clipboard
vim.keymap.set({'n', 'v'}, '<leader>y', '"+y')
vim.keymap.set('n', '<leader>Y', '"+Y')

-- Paste from system clipboard
vim.keymap.set('n', '<leader>p', '"+p')

-- Quick grep (requires ripgrep)
vim.keymap.set('n', '<leader>rg', ':grep ')
```

{: .prompt-warning }
`set clipboard=unnamedplus` makes the default yank/paste register the system clipboard. This means every `y` and `p` interacts with your system clipboard. Some people hate this (it clobbers your clipboard history). If that's you, remove this setting and use `"+y` / `"+p` explicitly.

---

## Cheat sheet summary

Here's the whole thing condensed into one page. Print it, stick it on your monitor, memorize it.

### Movement

```
h j k l          ← ↓ ↑ →
w W b B e E      word / WORD forward / backward
0 ^ $ g_         line start / first-non-blank / end / last-non-blank
f F t T ; ,      find char on line
gg G {n}G        file top / bottom / line n
Ctrl-d Ctrl-u    half-page scroll
Ctrl-f Ctrl-b    full-page scroll
zz zt zb         center / top / bottom cursor
H M L            screen top / mid / bottom
{ }              prev / next empty line
%                matching bracket
Ctrl-o Ctrl-i    jump list back / forward
```

### Search

```
/ pattern         search forward
? pattern         search backward
n N               next / prev match
* #               search word under cursor
:%s/old/new/gc    replace in file with confirm
:'<,'>s/old/new/g replace in visual selection
```

### Editing with text objects

```
ci"  change inside double quotes
ci'  change inside single quotes
ci{  change inside braces
ci(  change inside parens
ci[  change inside brackets
cit  change inside HTML/XML tag
dap  delete around paragraph
yaB  yank around braces block
```

### Marks

```
ma   set mark a
'a   jump to mark a (first non-blank)
`a   jump to mark a (exact column)
:marks  list marks
```

### Windows / buffers / tabs

```
:sp   :vsp        horizontal / vertical split
Ctrl-w hjkl       move between splits
Ctrl-w =          equalize splits
:bn :bp           next / prev buffer
Ctrl-^             toggle alternate buffer
gt gT             next / prev tab
```

### Folds

```
za   toggle fold
zo   open fold
zc   close fold
zR   open all
zM   close all
zj zk  next / prev fold
```

### Macros

```
qa   record into a
q    stop recording
@a   play back a
@@   play back last
{n}@a  play back n times
```

### DevOps power moves

```
.                  repeat last change
n .                search next, repeat
:v/ERROR/d         delete all non-matching lines
:g/TODO/d          delete all matching lines
:%s/\v(pattern)/new/g  very-magic replace
*                  search word under cursor
vi" ya"            yank inside quotes
vaB                select around braces
=ap                auto-indent paragraph
Ctrl-^             toggle last two buffers
```

---

## What's next

This is the stuff I use daily. There's always more to learn in Vim — I'm still discovering new tricks after years of use.

If you're starting out, don't try to memorize everything at once. Pick 3-4 movements you think would help your workflow right now, and force yourself to use them for a week. Then add more.

The muscle memory is the real value. Once `ci"` or `f:` becomes automatic, you'll wonder how you ever edited configs without it.

And if you're doing DevOps work and not using Vim motions yet — start. Even if it's just the Vim emulator in VS Code. You don't have to go full terminal Neovim to benefit. But once you do... 😎🎸

---

*P.S. Yes, I know about Helix and Kakoune. They're cool. I might try them. Someday. Maybe. But my muscle memory says Vim, and arguing with muscle memory is a losing battle 😅*

