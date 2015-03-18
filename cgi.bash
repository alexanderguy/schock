_bail () {
    if [[ $BASH_SUBSHELL -gt 0 ]] ; then
	kill -HUP $$
    fi

    exit 1
}
trap 's::response::finish' EXIT

_ALREADY_SENT_RESPONSE=false

s::response::finish () {
    [ "${_HEADERS['Content-Type']:-}" ] || log::error "no content-type specified"
    [ "${_HEADERS['Status']:-}" ] || log::error "no status specified"

    if $_REDIRECT ; then
        # Hook things back up to their original locations.
	exec 1>&${_REAL_STDOUT}
	exec 2>&${_REAL_STDERR}
    fi

    # Write the output of previous commands.

    if [ -s "$_TEMPDIR/stderr" ] ; then
	cat <<EOF
Content-Type: text/plain
Status: 500 Internal Server Error

Internal Server Error
=====================

An error was found while processing this request.

HEADERS
=======
EOF

	for h in "${!_HEADERS[@]}" ; do
	    echo "$h: ${_HEADERS[$h]}"
	done
	echo

	echo STDOUT
	echo ======
	cat $_TEMPDIR/stdout
	echo
	echo STDERR
	echo ======
	cat $_TEMPDIR/stderr
    elif ! $_ALREADY_SENT_RESPONSE ; then
	for h in "${!_HEADERS[@]}" ; do
	    echo "$h: ${_HEADERS[$h]}"
	done
	echo
	$_REDIRECT && cat $_TEMPDIR/stdout
    fi

    $_DEBUG && return

    if [ "$_TEMPDIR" -a -d "$_TEMPDIR" ] ; then
	rm -rf "$_TEMPDIR"
    fi
}

if $_DEBUG ; then
    _TEMPDIR=$TOP/debug_output
    mkdir -p $_TEMPDIR
    rm -rf $_TEMPDIR/*
else
    _TEMPDIR=$(mktemp -d)
fi

exec {_LOGFD}>>webapp.log

_REDIRECT=true

if $_REDIRECT ; then
    exec {_REAL_STDOUT}>&1
    exec {_REAL_STDERR}>&2

    exec 1>$_TEMPDIR/stdout
    exec 2>$_TEMPDIR/stderr
fi

[ "${CONTENT_LENGTH:-}" ] || CONTENT_LENGTH=0
[ "${REQUEST_METHOD:-}" ] || panic "REQUEST_METHOD unset."

if [ $CONTENT_LENGTH -gt 0 ] ; then 
    s::process-body $CONTENT_TYPE $CONTENT_LENGTH
fi

_gather_params () {
    local re='^(\w+)(=([^&]+)|)&?'
    while [[ $QUERY_STRING =~ $re ]] ; do
	QUERY_STRING=${QUERY_STRING##*${BASH_REMATCH[0]}}
	_QUERY_PARAMS[${BASH_REMATCH[1]}]=${BASH_REMATCH[3]}
    done
}

[ "${DOCUMENT_URI:-}" ] && PATH_INFO="$DOCUMENT_URI"

[ "${QUERY_STRING:-}" ] && _gather_params

s::run () {
    s::route::dispatch $REQUEST_METHOD ${PATH_INFO#$DOCUMENT_URI_BASE}
}
