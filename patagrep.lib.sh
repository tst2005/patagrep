patagrep_basedir=.


# _filters want argument like 'tag1=pat1' / 'not tag1=pat1' / 'not any tag1=' ; does not support single argument 'no'|'any'|'empty'
_patagrep() {
#echo >&2 "#debug# _patagrep ($#) [1=$1] $*"
	local s=' '
	local b="${b:-$s}" ;# word begin
	local e="${e:-$s}" ;# word end
	local pat="$1";shift
	if [ $# -eq 0 ]; then
		local invertmatch=false wantany=false wantempty=false
		while true; do
			case "$pat" in # invert match support
				('without '?*) invertmatch=true;;
				('with '?*) invertmatch=false;;
				('not '?*|'no '?*|'non '?*|'without '?*)
					${invertmatch:-false} && invertmatch=false || invertmatch=true
				;;
				('any '?*)
					if ${wantempty:-false}; then
						echo >&2 "ERROR: you can not 'any' and 'empty' on a single request"
						return 1
					fi
					wantany=true
				;;
				('empty '?*)
					if ${wantany:-false}; then
						echo >&2 "ERROR: you can not 'any' and 'empty' on a single request"
						return 1
					fi
					wantempty=true 
				;;
				('cmd '?*)
					local cmd="${pat#cmd }"
					local modsdirname="mods"
					if [ ! -f "${PATAGREP_DIR:-.}/$modsdirname/$cmd.cmd.sh" ]; then
						echo >&2 "$self: invalid command $cmd (${PATAGREP_DIR:-.}/$modsdirname/$cmd.cmd.sh)"
						return 1
					fi
#echo >&2 "command exists $cmd"
#					if [ ! -t 0 ]; then #pipe here
#echo >&2 "# there is data on the pipe for cmd $cmd)"
#					else
#echo >&2 "# no piped data before cmd $cmd"
#					fi

					if [ $# -eq 0 ]; then
#echo >&2 "#debug: run FINAL command (no more arg)"
						( patagrep_basedir="${patagrep_basedir:-.}/$modsdirname" . "${patagrep_basedir:-.}/$modsdirname/$cmd.cmd.sh" "$cmd"; )
						return $?
					fi
#echo >&2 "#debug: run PIPE command (there are $# more args)"
					( patagrep_basedir="${patagrep_basedir:-.}/$modsdirname" . "${patagrep_basedir:-.}/$modsdirname/$cmd.cmd.sh" "$cmd"; ) | "$self" "$@"
					return $?
				;;
				(*) break ;;
			esac
			pat="${pat#* }"
		done
		local grepopt; ${invertmatch:-false} && grepopt='-v' || grepopt=''

		if ${wantempty:-false}; then
			"${patagrep_grep:-grep}" $grepopt -- "$b""${pat%%=*}"'='"$e"
			return $?
		fi
		if ${wantany:-false}; then
			# match any value of this tag
			"${patagrep_grep:-grep}" $grepopt -- "$b""${pat%%=*}"'=.*'"$e"
			return $?
		fi
		case "$pat" in
#			(*=*==*);;
			(*'=='*) # match the exact pattern (do not include tag=ANY)
				"${patagrep_grep:-grep}" $grepopt -- "$b""${pat%==*}=${pat#*==}""$e"
				return $?
			;;
		esac
		# match the requested value (implicite include of tag=ANY)
		"${patagrep_grep:-grep}" $grepopt -- "$b"'\('"$pat"'\|'"${pat%=*}"'=ANY\)'"$e"
		return $?
	fi
	b="$b" e="$e" "_$self" "$pat" | b="$b" e="$e" "$self" "$@"
}
# this function is use to merge some argument with their prefix
# from 'not' 'empty' 'tag1=' 'any' 'tag2='
# to   'not empty tag1='     'any tag2='
patagrep() {
	local self="patagrep"
	local a1='' mods=''
	local defaultaction='auto' ;# PATAGREP_DEFAULT_MODE ?
#echo >&2 "$self: ($#) $*"
#	if [ $# -ge 2 ]; then
		local last=""
		while [ $# -gt 0 ]; do
			case "$1" in
			(cmd)
				# in correct case 'cmd' is the only prefix, the next argument is the command name.
				if [ -z "$last" ]; then
					last="$1 $2"
					shift 2
					break
				#else
				#	# this warning should be removed... valid case: with cmd foo 
				#	echo >&2 "WARN: ATTENTION cmd est utilisé mais last n'est pas vide (last=$last)"
				fi
			;;
			(filter)
				#if [ "$defaultaction" != "filter" ]; then
					defaultaction='filter';shift;continue
				#fi
			;;
			esac

			# TODO: faire depend les case du $defaultaction
			# if $defaultaction = cmd ...
			#	filter -> defaultaction=filter
			#	cmd => 'cmd $1'
			# if [ "$defaultaction" = "filter" ]; then
			#	...

			# a 'not'|'any'|'empty' prefix argument is pasted with the next argument
			local word="$1"
			case "$word" in
				(no|non) word=not ;;
				(w/o|with-out) word=without;;
				(w/) word=with;;
			esac
			case "$word" in
				(not|any|empty|with|without)
					last="${last:+$last }$word"
				;;
				('cmd '?*)
					last="$word";shift;break
				;;
				(*)
					local tmpaction="$defaultaction"
					case "$defaultaction" in
					(auto)
						case "$word" in
						(*=*) tmpaction='filter' ;;
						(*)   tmpaction='cmd' ;;
						esac
					;;
					esac
					case "$tmpaction" in
					(filter)
						last="${last:+$last }$word"
						shift
						break
					;;
					(cmd)
						if [ -n "$last" ]; then
							echo >&2 "no prefix suported in command mode, except 'cmd'"
							return 1
						fi
						defaultaction=auto
						last="cmd $word"
						shift
						break
					;;
					esac
				;;
			esac
			shift
		done
		if [ -n "$last" ]; then
			a1="$last"
		elif [ $# -ge 1 ]; then
			a1="$1";shift
		else
			local ret=$?
			if [ ! -t 0 ]; then
				cat - || return $?
			fi
			return $ret
			#echo >&2 "SOMETHING WRONG with a1"
			#return 0
		fi
#	else
#		a1="$1";shift
#	fi
#echo >&2 "_$self: a1=$a1 @=$*"
	"_$self" "$a1" "$@"
	return $?
}

