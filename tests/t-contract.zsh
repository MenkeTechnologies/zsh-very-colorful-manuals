#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-very-colorful-manuals — plugin-contract pins.
#####          Entrypoint stem matches plugin dir (typical
#####          zsh-plugin install pattern), entrypoint parses
#####          cleanly under `zsh -n`, and (where applicable)
#####          every completion file starts with `#compdef`.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
}

@test 'entrypoint stem matches plugin directory basename' {
    # The standard zsh-plugin install pattern (oh-my-zsh, zinit,
    # antibody, antigen) sources `<repo>/<repo>.plugin.zsh`. The
    # stem of `zsh-very-colorful-manuals.plugin.zsh` must equal the parent directory's
    # basename so generated source lines stay copy-pasteable.
    local entry='zsh-very-colorful-manuals.plugin.zsh'
    local stem="${entry%.plugin.zsh}"
    local dir="${pluginDir##*/}"
    # Accept either exact match or `zsh-` prefix on dir (some repos
    # like `docker-aliases.plugin.zsh` live under `zsh-docker-aliases`).
    [[ "$stem" == "$dir" || "zsh-$stem" == "$dir" ]]
    assert $state equals 0
}

@test 'entrypoint parses cleanly under zsh -n' {
    run zsh -n "$pluginDir/zsh-very-colorful-manuals.plugin.zsh"
    assert $state equals 0
}

@test 'every completion file starts with #compdef directive' {
    # Pass trivially when there are no `_*` files; otherwise every
    # one must lead with `#compdef`. A missing directive silently
    # disables completion. Use `find` so a zero-match doesn't trip
    # nomatch under EXTENDED_GLOB.
    local missing=""
    local d f
    for d in "$pluginDir/completions" "$pluginDir"; do
        [[ -d "$d" ]] || continue
        while IFS= read -r f; do
            [[ -f "$f" ]] || continue
            run head -1 "$f"
            [[ "$output" =~ ^#compdef ]] || missing="$missing ${f##*/}"
        done < <(find "$d" -maxdepth 1 -name "_*" -type f 2>/dev/null)
    done
    assert "$missing" is_empty
}

#--------------------------------------------------------------
# Round 2: man-wrapper contract pins
#--------------------------------------------------------------

@test 'plugin augments fpath with bin/ so `autoload -Uz man` finds the wrapper' {
    local body
    body=$(cat "$pluginDir/zsh-very-colorful-manuals.plugin.zsh")
    assert "$body" contains 'fpath+'
    assert "$body" contains 'bin'
}

@test 'autoload man directive present (the actual color-enable surface)' {
    # Without `autoload -Uz man` the bin/man function is never
    # registered as a callable wrapper; man calls hit the system
    # binary directly without the LESS_TERMCAP color setup.
    local body
    body=$(cat "$pluginDir/zsh-very-colorful-manuals.plugin.zsh")
    assert "$body" contains 'autoload'
    assert "$body" contains 'man'
}

@test 'bin/man is a zsh function file (no shebang)' {
    # autoload -Uz expects the file to BE the function body; a
    # shebang turns it into a standalone script and breaks
    # `autoload man` registration.
    local first
    first=$(head -1 "$pluginDir/bin/man")
    [[ "$first" != \#!* ]]
    assert $state equals 0
}

@test 'bin/man references LESS_TERMCAP_* for color escapes' {
    # The whole point of the wrapper is LESS_TERMCAP_md/us/so/me
    # color injection. Pin presence so a future minimal-deps
    # refactor doesn't drop them.
    run grep -E 'LESS_TERMCAP_(md|us|so|me)' "$pluginDir/bin/man"
    assert $state equals 0
}
