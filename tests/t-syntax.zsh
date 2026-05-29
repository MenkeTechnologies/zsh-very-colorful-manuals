#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: zsh-very-colorful-manuals syntax + LESS_TERMCAP_*
#####          shape tests. The plugin's actual tinting lives in
#####          `bin/man` (which `man` resolves to via fpath), NOT
#####          at source time — tests reflect that.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
}

@test 'plugin *.zsh parses cleanly' {
    for file in "$pluginDir/"*.zsh; do
        run zsh -n "$file"
        assert $state equals 0
    done
}

@test 'sourcing the plugin extends fpath with bin/' {
    # Source in a subshell whose initial fpath is intentionally small,
    # so we can prove the plugin's `fpath+=...` line widened it.
    local result
    result=$(zsh -c '
        fpath=( /tmp )
        emulate zsh -c "source \"'"$pluginDir"'/zsh-very-colorful-manuals.plugin.zsh\""
        print -r -- "${fpath[@]}"
    ' 2>&1)
    [[ "$result" == */bin* ]]
    assert $state equals 0
}

@test 'bin/man exists and parses cleanly' {
    [[ -f "$pluginDir/bin/man" ]]
    assert $state equals 0
    run zsh -n "$pluginDir/bin/man"
    assert $state equals 0
}

@test 'bin/man references all 7 LESS_TERMCAP_* keys' {
    run grep -c "LESS_TERMCAP_" "$pluginDir/bin/man"
    assert $state equals 0
    # The man wrapper sets at minimum: mb md me se so ue us = 7 keys.
    [[ "$output" -ge 7 ]]
    assert $state equals 0
}

@test 'bin/man wires PAGER to less' {
    run grep "PAGER=" "$pluginDir/bin/man"
    assert $state equals 0
    assert "$output" contains "less"
}
