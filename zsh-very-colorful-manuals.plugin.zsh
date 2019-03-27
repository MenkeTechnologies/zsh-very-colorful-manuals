if [[ "$OSTYPE" = solaris* ]]
then
	if [[ ! -x "$HOME/bin/nroff" ]]
	then
		mkdir -p "$HOME/bin"
		cat > "$HOME/bin/nroff" <<EOF
#!/bin/sh
if [ -n "\$_NROFF_U" -a "\$1,\$2,\$3" = "-u0,-Tlp,-man" ]; then
	shift
	exec /usr/bin/nroff -u\$_NROFF_U "\$@"
fi
#-- Some other invocation of nroff
exec /usr/bin/nroff "\$@"
EOF
		chmod +x "$HOME/bin/nroff"
	fi
fi

function man() {



	env \
		LESS_TERMCAP_mb=$(printf "\e[0;33;44m") \
		LESS_TERMCAP_md=$(printf "\e[0;32m") \
		LESS_TERMCAP_me=$(printf "\e[0;34m") \
		LESS_TERMCAP_se=$(printf "\e[33m") \
		LESS_TERMCAP_so=$(printf "\e[0;1;35m") \
		LESS_TERMCAP_ue=$(printf "\e[0;1;31m") \
		LESS_TERMCAP_us=$(printf "\e[1;36;4m") \
		PAGER="${commands[less]:-$PAGER}" \
		_NROFF_U=1 \
		PATH="$HOME/bin:$PATH" \
			man "$@"
}

