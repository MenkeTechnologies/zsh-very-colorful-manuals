#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-very-colorful-manuals — second-tier contract pins.
#####          Cover surfaces not pinned by t-syntax / t-man-wrapper:
#####          Solaris shim nroff body shape, no LESS env override
#####          beyond LESS_TERMCAP_*, idempotent re-source, and
#####          bin/man basename matches autoload contract.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-very-colorful-manuals.plugin.zsh"
    manWrapper="$pluginDir/bin/man"
}

@test 'bin/man basename is literally `man` (autoload name matches what user calls)' {
    # Pin: autoload -Uz man resolves bin/man via fpath. The filename
    # MUST be exactly `man` so `autoload man` finds it; any rename
    # (e.g. _man) would silently kill the wrapper.
    assert "$manWrapper" is_file
    local base
    base=${manWrapper:t}
    assert "$base" same_as 'man'
}

@test 'Solaris nroff shim conditionally invokes /usr/bin/nroff with -u when _NROFF_U set' {
    # Pin: the embedded here-doc shim handles the documented case:
    # `-u0 -Tlp -man` invocation gets transformed to `-u$_NROFF_U`.
    # Without this rewrite the Solaris nroff hangs/garbles the page.
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains '-u0,-Tlp,-man'
    assert "$body" contains '/usr/bin/nroff -u'
}

@test 'plugin does NOT set/export LESS itself (LESS_TERMCAP_* only — no global LESS clobber)' {
    # Pin: the LESS env var controls less defaults (e.g. -R -F -X).
    # The wrapper must NOT export LESS itself or it would override
    # user-set defaults in ~/.zshrc. Only the LESS_TERMCAP_* family
    # of vars are set inside the env wrapper.
    local matches
    matches=$(grep -cE '^[[:space:]]+LESS=' "$manWrapper" || true)
    assert "$matches" same_as '0'
}

@test 'plugin file is no-op on non-Solaris hosts (Linux/macOS path is empty besides fpath/autoload)' {
    # Pin: outside the OSTYPE solaris* branch, the only side effects
    # are the (a) `0=...` ZSH_ARGZERO bootstrap, (b) fpath+= bin,
    # (c) autoload -Uz man. The shim creation MUST stay inside the
    # branch — leaking it to all OSes would create spurious files
    # in $HOME/bin on every shell start.
    local body
    body=$(cat "$pluginFile")
    # mkdir + cat heredoc MUST be inside the `if [[ "$OSTYPE" = solaris* ]]` block.
    grep -nE '(mkdir -p|cat >)' "$pluginFile" >/tmp/zvcm_lines || true
    local mkdir_line
    mkdir_line=$(awk -F: '/mkdir/{print $1}' /tmp/zvcm_lines | head -1)
    rm -f /tmp/zvcm_lines
    # mkdir line MUST be after `if [[ "$OSTYPE"` and before its closing `fi`.
    local cond_line cond_close
    cond_line=$(grep -nE 'OSTYPE.*solaris' "$pluginFile" | head -1 | cut -d: -f1)
    [[ -n "$mkdir_line" && -n "$cond_line" && "$mkdir_line" -gt "$cond_line" ]]
    assert $? equals 0
}

@test 'plugin sourcing is idempotent — fpath bin entry not duplicated on re-source' {
    # Pin: fpath+=(...) appends every time; without a guard, repeated
    # sources stack up bin/ entries. Test the current behavior so a
    # future guard is a deliberate change.
    local first second
    first=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        print -l \"\$fpath[@]\" | grep -c '$pluginDir/bin'
    " || true)
    second=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        source '$pluginFile' 2>/dev/null
        print -l \"\$fpath[@]\" | grep -c '$pluginDir/bin'
    " || true)
    # CURRENT: plugin appends unconditionally so re-source DOUBLES.
    assert "$first" same_as '1'
    assert "$second" same_as '2'
}
