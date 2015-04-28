
declare -a _ROUTE_URI_RES
declare -a _ROUTE_URI_METHODS
declare -a _ROUTE_URI_HANDLERS

s::route::bind::uri () {
    # XXX - Is this explicit beginning and ending the correct choice?
    local pat="^$1$" ; shift
    local methods=$1 ; shift
    local handler=$1 ; shift

    pat="${pat//\[:pathseg:\]/[^\/]+}"

    log::debug "binding in route '$pat' '$methods' '$handler'"

    _ROUTE_URI_RES+=($pat)
    _ROUTE_URI_METHODS+=($methods)
    _ROUTE_URI_HANDLERS+=($handler)
}

s::route::bind::dir () {
    local dir=$1 ; shift
    log::debug "binding directory '$dir'..."

    local path
    while read path ; do 
	local pattern method
	pattern=$(dirname ${path#./})
	method=$(basename $path)

	log::debug "pattern '$pattern'"

	s::route::bind::uri "/$pattern" $method $dir/$path

    done < <(cd $dir && find -L . -executable -type f)
}

s::route::exec-handler () {
    local handler=$1 ; shift

    log::debug "executing handler with args '$@'"
    local t=$(type $handler | head -1) || panic "unknown handler '$handler'"

    case $t in
	*is\ a\ function)
	    $handler "$@"
	    ;;
	*)
	    set -- "$@"
	    . $handler
	    ;;
    esac
}

_S_ROUTE_METHOD=""

s::method () {
    [[ -z "$_S_ROUTE_METHOD" ]] && panic "method is blank, how did that happen?"
    echo "$_S_ROUTE_METHOD"
}

s::route::dispatch () {
    local method=$1 ; shift
    local uri=$1; shift
    local args=()

    _S_ROUTE_METHOD=$method

    local handler
    res=0

    handler="$(s::route::lookup-handler $method $uri)" || res=$?

    case $res in
	0)
	    readarray -t args < <(echo "$handler")
	    log::debug "handler is '$handler'"
	    s::route::exec-handler "${args[@]}"
	    ;;
	254)
	    error 405
	    ;;
	255)
	    error 404
	    ;;
	*)
	    error 500
	    ;;
    esac
}

s::route::lookup-handler() {
    local request_method=$1 ; shift
    local uri=$1 ; shift

    log::debug "looking up handler for $request_method on '$uri'"

    local match=("")
    local handler=""
    local closebutnocigar=false
    for i in "${!_ROUTE_URI_RES[@]}" ; do
	if [[ $uri =~ ${_ROUTE_URI_RES[$i]} ]] ; then
	    if [ "${#match[0]}" -le "${#BASH_REMATCH[0]}" ] ; then
		match=("${BASH_REMATCH[@]}")

		if [[ $request_method =~ ${_ROUTE_URI_METHODS[$i]} ]] ; then
		    handler=${_ROUTE_URI_HANDLERS[$i]}
		else
		    closebutnocigar=true
		fi
	    fi
	fi
    done

    if [ "$handler" ] ; then
	echo $handler
	for i in "${match[@]}" ; do
	    echo $i
	done
	return 0
    fi

    if $closebutnocigar ; then
	return 254
    else
	return 255
    fi
}
