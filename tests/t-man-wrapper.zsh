#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: bin/man wrapper LESS_TERMCAP_* contract pins.
#####          The whole point of this plugin is to inject ANSI
#####          color escapes into less for man-page rendering.
#####          Tests pin EXACT escape sequences per termcap key so
#####          a refactor can't silently change the color palette.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-very-colorful-manuals.plugin.zsh"
    manWrapper="$pluginDir/bin/man"
}

@test 'bin/man defines an __man() helper (not the public name)' {
    # Pin: the inner fn is named __man so the OUTER `man` call (at
    # the end via `man "$@"`) is the SYSTEM man — not recursive.
    # Renaming __man to man would make the wrapper infinite-loop.
    local body
    body=$(cat "$manWrapper")
    assert "$body" contains 'function __man()'
}

@test 'bin/man invokes the system man via env-wrapper (NOT exec/source)' {
    # Pin: env launches a fresh subprocess with the LESS_TERMCAP_*
    # vars in its environment. exec would replace the caller; source
    # would not isolate the env vars (they'd leak into the user's
    # shell forever).
    local body
    body=$(cat "$manWrapper")
    assert "$body" contains 'env'
    assert "$body" contains 'man "$@"'
}

@test 'LESS_TERMCAP_mb (blink) — yellow-on-blue 0;33;44m' {
    # Pin EXACT SGR sequence. Refactor to e.g. 1;33;44 (bold yellow)
    # would silently change the blink rendering. grep with two
    # patterns so we never write a string with literal $( in it.
    grep 'LESS_TERMCAP_mb' "$manWrapper" | grep -q '0;33;44m'
    assert $? equals 0
}

@test 'LESS_TERMCAP_md (bold start) — green 0;32m (headings)' {
    grep 'LESS_TERMCAP_md' "$manWrapper" | grep -q '0;32m'
    assert $? equals 0
}

@test 'LESS_TERMCAP_me (bold end) — blue 0;34m (reset+blue)' {
    grep 'LESS_TERMCAP_me' "$manWrapper" | grep -q '0;34m'
    assert $? equals 0
}

@test 'LESS_TERMCAP_se (standout end) — yellow 33m' {
    grep 'LESS_TERMCAP_se' "$manWrapper" | grep -q '33m'
    assert $? equals 0
}

@test 'LESS_TERMCAP_so (standout start) — bright magenta 0;1;35m (mode/search)' {
    # Pin: standout is what less uses for the (END) marker and
    # search matches. High-contrast magenta for instantly visible
    # interaction state.
    grep 'LESS_TERMCAP_so' "$manWrapper" | grep -q '0;1;35m'
    assert $? equals 0
}

@test 'LESS_TERMCAP_ue (underline end) — bright red 0;1;31m' {
    grep 'LESS_TERMCAP_ue' "$manWrapper" | grep -q '0;1;31m'
    assert $? equals 0
}

@test 'LESS_TERMCAP_us (underline start) — bold cyan-underline 1;36;4m (option names)' {
    # Pin: bold cyan + underline (the ;4 SGR for underline) is the
    # canonical color for command-line option names in man pages.
    grep 'LESS_TERMCAP_us' "$manWrapper" | grep -q '1;36;4m'
    assert $? equals 0
}

@test 'bin/man covers exactly 7 LESS_TERMCAP_* keys (the full less termcap set)' {
    # Pin: less recognizes 7 LESS_TERMCAP_* keys (mb md me se so ue us).
    # Fewer = under-coloring some part of man output.
    # More = a typo / spurious key.
    local count
    count=$(grep -c 'LESS_TERMCAP_' "$manWrapper")
    assert "$count" same_as '7'
}

@test 'bin/man prefers $commands[less] over $PAGER (consistency guarantee)' {
    # Pin: ${commands[less]:-$PAGER} resolves zsh's hash for `less`
    # first, falling back to $PAGER. Without this, users with
    # PAGER=most lose the LESS_TERMCAP coloring (since most ignores
    # those vars).
    grep 'PAGER=' "$manWrapper" | grep -q 'commands\[less\]'
    assert $? equals 0
}

@test 'bin/man sets _NROFF_U=1 (Solaris nroff EUC encoding flag)' {
    # Pin: _NROFF_U is read by the plugin’s shim nroff on Solaris.
    # Removing it silently breaks the Solaris branch of the plugin.
    local body
    body=$(cat "$manWrapper")
    assert "$body" contains '_NROFF_U=1'
}

@test 'bin/man prepends $HOME/bin to PATH (so the Solaris shim is reachable)' {
    # Pin: the plugin file creates $HOME/bin/nroff on Solaris. The
    # bin/man wrapper MUST put $HOME/bin first so that shim is
    # picked up over /usr/bin/nroff.
    local body
    body=$(cat "$manWrapper")
    assert "$body" contains 'PATH="$HOME/bin:$PATH"'
}

@test 'bin/man self-invokes __man "$@" at the bottom (autoload pattern)' {
    # Pin: zsh autoload sources the file once to define __man, but
    # the trailing `__man "$@"` is what actually invokes it when
    # the autoloaded `man` shadow runs.
    local last
    last=$(grep -E '^__man ' "$manWrapper" | tail -1)
    assert "$last" same_as '__man "$@"'
}

@test 'plugin file ships Solaris-specific nroff shim creation' {
    # Pin: the OSTYPE solaris branch in the entry plugin creates
    # $HOME/bin/nroff dynamically (the Solaris nroff lacks -u).
    # If the branch drops, Solaris users get unreadable man pages.
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'OSTYPE'
    assert "$body" contains 'solaris*'
    assert "$body" contains '$HOME/bin/nroff'
    assert "$body" contains '_NROFF_U'
}

@test 'plugin file augments fpath with ${0:h}/bin via fpath+= (not fpath=)' {
    # Pin: fpath+=(...) PRESERVES existing fpath; fpath=(...) would
    # WIPE it. Using = here would silently strip every other plugin.
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'fpath+="${0:h}/bin"'
}

@test 'plugin file autoloads man (which resolves via fpath to bin/man)' {
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'autoload -Uz man'
}

@test 'sourcing the plugin makes man visible via whence -v (autoload-ready)' {
    # End-to-end: confirm the autoload registration actually
    # resolves the man wrapper.
    local out
    out=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        whence -v man
    " 2>&1)
    assert "$out" contains 'man'
}

@test 'env-wrapper line-continuations work (bash -n parses the whole env block)' {
    # Pin: each env-arg line ends with `\<newline>` so bash joins
    # them into one env invocation. If a line ever LOSES the
    # trailing backslash, bash -n won't catch it (env would just
    # become orphan, then the next line is a fresh command). But
    # we CAN pin that the count of backslash-continuations matches
    # what we expect — fewer means an arg got accidentally split.
    local cont_count
    cont_count=$(grep -cE '\\$' "$manWrapper")
    # We expect at least 11 continuation lines (env + 7 LESS_TERMCAP +
    # PAGER + _NROFF_U + PATH).
    local result=$([[ "$cont_count" -ge 11 ]] && echo yes || echo "no:$cont_count")
    assert "$result" same_as 'yes'
}
