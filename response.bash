### Result methods.

# These should be somewhere else.
declare -A _HEADERS

header () {
    if [ "${2:-}" ] ; then 
	_HEADERS["$1"]="$2"
    else
	echo ${_HEADERS["$1"]}
    fi
}

status () {
    [ "${1:-}" ] || panic "status requires an argument"
    header Status $1
}

content-type () {
    [ -n "$1" ] || panic "content-type is required."
    
    header Content-Type $1
}

success () {
    status $1
    s::comp::reset
    if [[ -n "${2:-}" ]] ; then
	s::comp::string "/message" "$2"
    fi

    content-type "application/json"
    s::comp::generate "application/json"

    _bail
}

error () {
    status $1
    content-type "application/json"

    if [[ -n "${2:-}" ]] ; then
	echo "\"$2\""
    else
	# We should look up the HTTP error string here.
	echo "\"$1\""
    fi

    _bail
}

### Structured Response Composition

_LAST_KEY=""
s::comp::last-key () {
    echo "$_LAST_KEY"
}

s::comp::_last-fname () {
    echo "$_TEMPDIR/comp/$_LAST_KEY"
}

s::comp::reset () {
    rm -rf "$_TEMPDIR/comp"
    mkdir -p "$_TEMPDIR/comp"
}

s::comp::_make-key () {
    local key=$1 ; shift

    [[ $key ]] || panic "attempt to use an empty key"
    [[ $key =~ ^/ ]] || panic "at present, keys must be absolute."

    local parentkey=$(dirname "$key")
    if [[ $parentkey = "/" ]] ; then
	parentkey=""
    fi

    local t="$_TEMPDIR/comp/$parentkey/.array"

    if [[ -e "$t" ]] ; then
	case $(basename "$key") in
	    APPEND)
		local v=$(cat "$t")
		echo $(( $v + 1 )) > "$t"
		key="$parentkey/$v"
	esac
    fi

    _LAST_KEY=$key
}

s::comp::_dir () {
    echo "$_TEMPDIR/comp/$1"
}

s::comp::obj () {
    [[ $# -eq 1 ]] || panic "object only takes one arg."
    s::comp::_make-key "$1"

    local d=$(s::comp::_last-fname)
    if [[ -e "$d" ]] ; then
	rm -rf $d
    fi

    mkdir $d || panic "unable to create directory 'fname'"
}

s::comp::string () {
    [[ $# -eq 2 ]] || panic "string takes two args: key value"

    s::comp::_make-key "$1" ; shift
    local value=$1 ; shift

    echo -n "$value" > "$(s::comp::_last-fname)"
}

s::comp::string-from-file () {
    [[ $# -eq 2 ]] || panic "string takes two args: key value"

    s::comp::_make-key "$1" ; shift
    local src=$1 ; shift

    [[ -e $src ]] || panic "filename '$src' doesn't exist."
    
    cp "src" "$(s::comp::_last-fname)"
}

s::comp::array () {
    s::comp::obj "$1"
    echo 0 > "$(s::comp::_last-fname)/.array"
}

s::comp::generate () {
    [[ $# -eq 1 ]] || panic "generate only takes one arg: the content-type required."

    local type=$1 ; shift

    case $type in 
	text/json|application/json)
	    $SCHOCKDIR/dir2json $_TEMPDIR/comp
	    ;;
	*)
	    panic "unknown content type."
	    ;;
    esac
}

content-type "text/plain"
status 200
