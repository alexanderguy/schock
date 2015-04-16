
[ "${_DEBUG:-}" ] || _DEBUG=false

set -uo pipefail
set -o privileged
set -o noglob
set -o errtrace
set -e
IFS=$'\n'

_err_report () {
    err_status=$1
    trap - ERR

    status 500
    cat 1>&2 <<EOF
problem executing commands:
EOF

    local i=0
    while caller $i 1>&2; do
	((i += 1))
    done
    exit $err_status
}

trap '_err_report $?' ERR

_EXIT_FUNCS=()

_exit_cascade () {
    local i
    for (( i = ${#_EXIT_FUNCS[@]} - 1 ; i >= 0 ; i-- )) ; do
	${_EXIT_FUNCS[$i]}
    done
}

trap '_exit_cascade' EXIT

if $_DEBUG ; then
    _TEMPDIR=$TOP/debug_output
    rm -rf $_TEMPDIR
    mkdir -p $_TEMPDIR
else
    _TEMPDIR=$(mktemp -d)
fi

_cleanup_tempdir () {
    $_DEBUG && return
    [[ -d "$_TEMPDIR" ]] || return 0
    rm -rf $_TEMPDIR
}

_EXIT_FUNCS+=(_cleanup_tempdir)

. $SCHOCKDIR/util.bash
. $SCHOCKDIR/logging.bash
. $SCHOCKDIR/response.bash

s::comp::reset

. $SCHOCKDIR/args.bash

# XXX - Is there a better way to check that we're a CGI?
if [[ "${REQUEST_METHOD:-}" ]] ; then
    . $SCHOCKDIR/cgi.bash
else
    . $SCHOCKDIR/cli.bash
fi

