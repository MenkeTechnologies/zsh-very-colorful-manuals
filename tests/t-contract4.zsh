#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-very-colorful-manuals — fourth-tier contracts.
#####          Pins for the env-wrapper exec shape: all seven
#####          LESS_TERMCAP_* vars carried into the subprocess,
#####          PAGER fallback to commands[less] then $PAGER, _NROFF_U=1
#####          for Solaris underline support, and PATH-prepend with
#####          $HOME/bin so the Solaris shim is found first.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    manFile="$pluginDir/bin/man"
}

@test 'all seven LESS_TERMCAP_* vars are exported into the env subprocess' {
    # Pin: mb, md, me, se, so, ue, us — the canonical less-termcap set.
    # Dropping any one would leave a specific text style (bold, blink,
    # standout, underline) uncolored in man output. Pin by count.
    local count
    count=$(grep -cE '^[[:space:]]+LESS_TERMCAP_(mb|md|me|se|so|ue|us)=' "$manFile")
    assert "$count" same_as '7'
}

@test 'PAGER falls back to commands[less] then user-set PAGER' {
    # Pin: `PAGER="${commands[less]:-$PAGER}"`. The `${commands[less]}`
    # form uses zsh's commands assoc-array — resolves the absolute path
    # to less. Falling back to `$PAGER` preserves user override when
    # less is absent. Pin the exact expansion shape.
    grep -qF 'PAGER="${commands[less]:-$PAGER}"' "$manFile"
    assert $? equals 0
}

@test '_NROFF_U=1 is set in the env block (Solaris underline support)' {
    # Pin: the Solaris nroff shim (installed by the plugin entrypoint
    # when OSTYPE=solaris*) reads _NROFF_U to enable underline mode.
    # Dropping the var here means colorful headers regress on Solaris.
    grep -qE '^[[:space:]]+_NROFF_U=1' "$manFile"
    assert $? equals 0
}

@test 'PATH is prepended with $HOME/bin (Solaris nroff shim takes priority)' {
    # Pin: `PATH="$HOME/bin:$PATH"`. The shim is installed under
    # $HOME/bin/nroff by the plugin's Solaris branch; prepending makes
    # it shadow /usr/bin/nroff. Reversing the order (`$PATH:$HOME/bin`)
    # would let system nroff run first and lose the -u underline flag.
    grep -qF 'PATH="$HOME/bin:$PATH"' "$manFile"
    assert $? equals 0
}

@test 'env wrapper ends with `man "$@"` (passthrough of caller args)' {
    # Pin: the trailing `man "$@"` quoted-array expansion passes every
    # caller argument unchanged. Unquoting or using `man $*` would
    # word-split arguments with spaces (man page titles can contain
    # spaces in rare distributions).
    grep -qE '^[[:space:]]+man "\$@"' "$manFile"
    assert $? equals 0
}
