# Start off with logging going to stderr.
_LOGFD=2

log::cmd () {
    log::info "running command: $*"
    "$@" >&${_LOGFD} 2>&1
    local ret=$?

    log::debug "return value was $ret"
    return $ret
}

log::debug () {
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
