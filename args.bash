s::process-body () {
    local contenttype=$1 ; shift
    local contentlength=$1 ; shift

    RESULT=$(dd bs=$contentlength count=1 of=$_TEMPDIR/body 2>&1) || panic "failed to read body $RESULT"

    case $contenttype in
	multipart/form-data*)
	    (
		cat <<EOF
Content-Type: $contenttype

EOF
		cat $_TEMPDIR/body
	    ) > $_TEMPDIR/mimebits
	    while IFS=$'\t' read name fname ; do
		val="$(cat $_TEMPDIR/$fname)"
		log::debug "pulling field from form: $fname -> $name"
		_QUERY_PARAMS[$name]=$val
	    done < <(cd $_TEMPDIR && rm -rf form && $SCHOCKDIR/mimeout < mimebits)

	    rm $_TEMPDIR/mimebits
	    ;;
	*)
	    error 503 "unknown post content type."
	    ;;
    esac
}

declare -A _QUERY_PARAMS

s::param::exists () {
    for p in "$@" ; do
	query_param $p || return 1
    done

    return 0
}

s::param () {
    [ "${_QUERY_PARAMS[$1]-}" ] || return 1
    echo "${_QUERY_PARAMS[$1]-}"
    return 0
}

s::param::dump () {
    log::debug "Dumping passed in arguments:"

    for k in "${!_QUERY_PARAMS[@]}" ; do
	log::debug "$k: ${_QUERY_PARAMS[$k]}"
    done
}
