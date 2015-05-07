s::external-uri-prefix () {
    local prefix
    prefix="${HTTP_X_EXTERNAL_URI_PREFIX:-}${DOCUMENT_URI_BASE:-}"
    echo $prefix
}
