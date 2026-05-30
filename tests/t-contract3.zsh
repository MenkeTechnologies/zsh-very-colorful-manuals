#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-very-colorful-manuals — third-tier surface pins:
#####          - every LESS_TERMCAP_* value parses as a valid ANSI SGR sequence
#####          - LESS_TERMCAP_* escapes do NOT leak into the parent shell
#####          - bin/man does NOT contain bashism `function name()` shape
#####          - Solaris shim cat-heredoc is delimited by EOF (NOT 'EOF' — interpolation)
#####          - env wrapper terminates with bare `man "$@"` (not exec, not source)
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-very-colorful-manuals.plugin.zsh"
    manFile="$pluginDir/bin/man"
}

@test 'every LESS_TERMCAP_* SGR escape is a valid ANSI sequence (digits + semicolons + m)' {
    # Pin: every escape MUST match `\e[<digits>(;<digits>)*m`. A malformed
    # sequence (missing trailing m, stray space) would render as literal
    # characters in the pager.
    local invalid="" line code
    # Extract every `\e[...m` from the LESS_TERMCAP_* declarations
    while IFS= read -r line; do
        # parse the `printf "\e[CODEm"` payload
        code=$(printf '%s' "$line" | grep -oE 'e\[[0-9;]+m' || true)
        [[ -z "$code" ]] && continue
        # validate: starts with e[, ends with m, middle is digits/semicolons
        [[ "$code" =~ ^e\[[0-9]+(\;[0-9]+)*m$ ]] || invalid="$invalid '$code'"
    done < <(grep 'LESS_TERMCAP_' "$manFile")
    assert "$invalid" is_empty
}

@test 'LESS_TERMCAP_* settings do NOT leak into parent shell (env-only scope)' {
    # Pin: the wrapper uses `env LESS_TERMCAP_x=...` form, NOT `export`.
    # That means the escapes apply only to the `man` invocation; the
    # parent shell's PAGER colors are untouched. `export LESS_TERMCAP_*`
    # would silently pollute every other less invocation.
    local exports
    exports=$(grep -E '^[[:space:]]*export[[:space:]]+LESS_TERMCAP_' "$manFile" | head -1)
    assert "$exports" is_empty
}

@test 'bin/man uses zsh `function NAME()` shape (NOT POSIX `name()`)' {
    # Pin: the wrapper declares `function __man()` — the `function`
    # keyword is zsh/bash extension. The plugin is autoloaded by zsh
    # only, so the explicit `function` keyword pins the intended
    # parser path (autoload-without-+X).
    grep -qE '^function __man\(\)' "$manFile"
    assert $? equals 0
}

@test 'Solaris nroff shim heredoc body interpolates $1/$2/$3 at write-time (delimiter is EOF, not "EOF")' {
    # Pin: the heredoc must use UN-quoted `EOF` so the dollar-sign refs
    # in the body are interpolated by the OUTER zsh (the shim is a
    # static file). Quoted 'EOF' would pass `\$1` literal into the shim,
    # which would not work as expected. The plugin uses literal EOF.
    grep -qE "<<EOF[[:space:]]*$" "$pluginFile"
    assert $? equals 0
}

@test 'env wrapper invokes plain `man` (not exec/source/eval) at the bottom' {
    # Pin: the final command inside `env ...` is `man "$@"` — a regular
    # invocation. Replacing with `exec man "$@"` would replace the shell
    # PID and break ZSH job control; `source` would run man as a script.
    grep -qE 'man "\$@"' "$manFile"
    assert $? equals 0
}
