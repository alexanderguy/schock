
declare -A _FORM_FILES

s::process-body () {
    local contenttype=$1 ; shift
    local contentlength=$1 ; shift

    log::cmd dd bs=1 count=$contentlength of=$_TEMPDIR/body || panic "failed to read body $RESULT"
    case $contenttype in
	multipart/form-data*)
	    (
		cat <<EOF
Content-Type: $contenttype

EOF
		cat $_TEMPDIR/body
	    ) > $_TEMPDIR/mimebits
	    while IFS=$'\t' read name fname ; do
		log::debug "pulling field from form: $fname -> $name"
		_FORM_FILES[$name]=$_TEMPDIR/$fname
	    done < <(cd $_TEMPDIR && rm -rf form && $SCHOCKDIR/mimeout < mimebits)

	    rm $_TEMPDIR/mimebits
	    ;;
	*)
	    error 503 "unknown post content type."
	    ;;
    esac
}

declare -A _QUERY_PARAMS

s::param () {
    if [[ -n "${_QUERY_PARAMS[$1]-}" ]] ; then
	echo "${_QUERY_PARAMS[$1]-}"
	return 0
    elif [[ -n "${_FORM_FILES[$1]-}" ]] ; then
	cat ${_FORM_FILES[$1]}
	return 0
    fi

    return 1
}

s::param::file () {
    if [[ -n "${_FORM_FILES[$1]-}" ]] ; then
	echo ${_FORM_FILES[$1]}
	return 0
    fi

    return 1
}

s::param::dump () {
    log::debug "Dumping passed in arguments:"

    for k in "${!_QUERY_PARAMS[@]}" ; do
	log::debug "$k: ${_QUERY_PARAMS[$k]}"
    done

    for k in "${!_FORM_FILES[@]}" ; do
	log::debug "$k: ${_FORM_FILES[$k]}"
    done
}
