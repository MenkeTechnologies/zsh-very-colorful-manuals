```
__     __    _     _     ____  ____  _   _  ____
\ \   / /\  | |   | |   |  __|/ ___|| | | || ___|
 \ \ / / _ \ | |   | |   | |  | |  _ | |_| || |__
  \ V / ___ \| |___| |__ | |__| |_| ||  _  ||  __|
   \_/_/   \_\_____|_____|_____\____||_| |_||_|
        __  __    _    _   _    ____   _     ____  ____  ____
       |  \/  |  / \  | \ | |  |  _ \ / \   / ___|| ___|/ ___|
       | |\/| | / _ \ |  \| |  | |_) / _ \ | |  _ |  __|\___ \
       | |  | |/ ___ \| |\  |  |  __/ ___ \| |_| || |___ ___) |
       |_|  |_/_/   \_\_| \_|  |_| /_/   \_\____|_____|____/
```

<p align="center">
<code>// `man <cmd>` IS GREEN ON BLACK NOW. NEON HEADERS. UNDERLINED EXAMPLES. NO MORE GRAYSCALE WALLS OF TEXT.</code>
</p>

---

[![Tag](https://img.shields.io/badge/tag-v0.1.0-39ff14.svg)](https://github.com/MenkeTechnologies/zsh-very-colorful-manuals/tags)
[![Shell](https://img.shields.io/badge/shell-zsh-05d9e8.svg)](#install)
[![Backend](https://img.shields.io/badge/backend-less%20env-d300c5.svg)](#how-it-works)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

### `[SIGNAL // RE-PAINTS THE TERMINAL'S `man` OUTPUT WITH CYBERPUNK ANSI COLORS]`

> *// jacking your man pages into the same neon palette as the rest of your zsh — headers POP, examples GLOW //*

---

## `> SYSTEM OVERVIEW`

`zsh-very-colorful-manuals` exports the `LESS_TERMCAP_*` env vars that `man`'s pager (`less` by default) consults for bold/underline/standout rendering. Result: `man <anything>` looks like the rest of your cyberpunk terminal — bright headers, glowing keywords, underlined options.

Zero runtime cost. One sourced plugin. Works in every man page on the system.

---

## `> HOW IT WORKS`

`man` pipes its rendered output through a pager (usually `less`). `less` reads `LESS_TERMCAP_md` for bold, `LESS_TERMCAP_us` for underline, `LESS_TERMCAP_so` for standout, etc. This plugin sets all eight to neon ANSI escape codes:

```
[x] LESS_TERMCAP_md (bold)       → bright magenta
[x] LESS_TERMCAP_us (underline)  → bright cyan
[x] LESS_TERMCAP_so (standout)   → black-on-yellow status line
[x] LESS_TERMCAP_me / _ue / _se  → reset
[x] LESS_TERMCAP_mb (blink)      → bright red
```

No `man` config touched. No system theme installed. Pure shell-env tinting.

---

## `> INSTALL`

### Zinit

```sh
zinit ice lucid nocompile
zinit load MenkeTechnologies/zsh-very-colorful-manuals
```

### Oh My Zsh

```sh
cd "$HOME/.oh-my-zsh/custom/plugins" && \
  git clone https://github.com/MenkeTechnologies/zsh-very-colorful-manuals.git
```

Add `zsh-very-colorful-manuals` to the `plugins=(...)` array in `~/.zshrc`.

### Manual

```sh
git clone https://github.com/MenkeTechnologies/zsh-very-colorful-manuals.git
source zsh-very-colorful-manuals/zsh-very-colorful-manuals.plugin.zsh
```

---

## `> TRY IT`

```sh
man ls          # bright cyan flags, magenta DESCRIPTION header
man git-rebase  # examples GLOW
man bash        # 4000-line manual finally readable
```

---

## `> LICENSE`

[MIT](https://opensource.org/licenses/MIT)

---

<p align="center">
<code>// END OF FILE // PAGER LOCKED //</code>
</p>
