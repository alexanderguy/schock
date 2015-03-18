_bail () {
    exit 0
}

usage () {
    echo "usage: $0 <method> <path> [k=v ...]" >&2
    exit 1
}

s::run () {
    [[ $# -ge 2 ]] || usage

    local method=$1 ; shift
    local path=$1 ; shift

    local k v t
    while [[ $# -gt 0 ]] ; do
	k=${1%%\=*}
	v=${1#*\=}
	shift
	# TODO - Don't touch query params directly.
	_QUERY_PARAMS[$k]=$v
    done

    s::param::dump
    s::route::dispatch $method $path
}

s::response::finish () {
    log::info "response finished"
    for h in "${!_HEADERS[@]}" ; do
	log::info "Header $h: ${_HEADERS[$h]}"
    done
}

