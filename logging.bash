# Start off with logging going to stderr.
_LOGFD=2

log::cmd () {
    local ret

    ret=0
    log::info "running command: $*"
    "$@" >&${_LOGFD} 2>&1 || ret=$?

    log::debug "return value was $ret"
    return $ret
}

log::debug () {
    $_DEBUG || return 0
    echo DEBUG: $* >&${_LOGFD}
    true
}

log::error () {
    echo ERROR: $* >&${_LOGFD}
}

log::info () {
    echo INFO: $* >&${_LOGFD}
}

panic () {
    echo PANIC: $* >&${_LOGFD}
    echo PANIC $* >&2

    _bail
}
