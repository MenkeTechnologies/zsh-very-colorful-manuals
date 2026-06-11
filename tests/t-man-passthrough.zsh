#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: bin/man BEHAVIORAL passthrough tests.
#####          Every other test in this suite greps the SOURCE
#####          TEXT of bin/man. These two actually EXECUTE __man
#####          through a PATH-shimmed fake `man` and inspect the
#####          argv + environment the real `man` would receive.
#####
#####          Bug class: argument quoting/word-splitting. The
#####          wrapper ends with `env ... man "$@"`. The "$@"
#####          must survive verbatim — spaces, glob chars, unicode,
#####          and command-substitution-looking literals must NOT
#####          be split, expanded, or globbed on their way through
#####          env into man. A refactor to `man $*`, `man $@`
#####          (unquoted), or eval-based dispatch would silently
#####          mangle real-world man invocations like
#####          `man "Tcl_NewObj"` or titles containing spaces.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    manFile="$pluginDir/bin/man"
}

@test 'env wrapper passes argv verbatim — spaces, globs, unicode, $()-literal survive' {
    # Adversarial argv. If any of these get word-split, glob-expanded,
    # or command-substituted, ARGC drops below 4 or an ARG line changes.
    local out
    out=$(zsh -c '
        set -e
        manFile="'"$manFile"'"

        # Isolate HOME so the wrappers `PATH="$HOME/bin:$PATH"` prepend
        # cannot shadow our stub with a real $HOME/bin/man.
        export HOME="$(mktemp -d)"

        # PATH-shimmed fake man: env bypasses shell functions, so the
        # only way to intercept the real call is a real executable.
        stubdir="$(mktemp -d)"
        cat > "$stubdir/man" <<STUB
#!/bin/sh
printf "ARGC=%s\n" "\$#"
for a in "\$@"; do printf "ARG=[%s]\n" "\$a"; done
STUB
        chmod +x "$stubdir/man"
        export PATH="$stubdir:$PATH"

        # Define __man WITHOUT triggering the trailing self-invocation.
        eval "$(sed "/^__man /d" "$manFile")"

        __man "a b" "*.gz" "café" "\$(echo PWNED)"
    ' 2>&1)

    # Exactly four args reached man — nothing split, nothing dropped.
    assert "$out" contains 'ARGC=4'
    # Space-containing title kept as ONE arg.
    assert "$out" contains 'ARG=[a b]'
    # Glob pattern passed LITERALLY (not expanded against cwd).
    assert "$out" contains 'ARG=[*.gz]'
    # Multibyte/unicode arg intact.
    assert "$out" contains 'ARG=[café]'
    # Command-substitution-looking arg is a LITERAL, never executed.
    assert "$out" contains 'ARG=[$(echo PWNED)]'
    # If $() had executed, the literal would become ARG=[PWNED].
    assert "$out" does_not_contain 'ARG=[PWNED]'
}

@test 'LESS_TERMCAP_mb crosses env boundary as a real ESC (\x1b) byte, not literal text' {
    # bin/man builds the value with $(printf "\e[0;33;44m"). A regression
    # to a single-quoted literal "\e[0;33;44m" would put the 2 chars
    # backslash+e into the environment instead of the 0x1b control byte,
    # and less would render the escape as garbage text. This proves the
    # printf actually evaluated and the byte survives into the subprocess.
    local out
    out=$(zsh -c '
        set -e
        manFile="'"$manFile"'"
        export HOME="$(mktemp -d)"
        stubdir="$(mktemp -d)"
        # Emit MB as a hexdump so a real 0x1b is distinguishable from "\e".
        cat > "$stubdir/man" <<STUB
#!/bin/sh
printf "%s" "\$LESS_TERMCAP_mb" | od -An -tx1 | tr -d " \n"
STUB
        chmod +x "$stubdir/man"
        export PATH="$stubdir:$PATH"
        eval "$(sed "/^__man /d" "$manFile")"
        __man ls
    ' 2>&1)

    # 0x1b ESC followed by "[0;33;44m" = 1b 5b 30 3b 33 33 3b 34 34 6d
    assert "$out" contains '1b5b303b33333b34346d'
}
