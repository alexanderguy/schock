schock
======

"We need [new technology], not these unmaintainable bash scripts."

- Anonymous

Introduction
------------

schock is a web services framework written (mostly) in bash.  It was built to provide rapid
development, experimentation, and testing with minimal effort.  Depending on the code you
plug into it, it should be reasonably secure, and fast enough for development work.

Use this in production at your own peril.  It's the result of a bunch of hacking over a couple of days,
and probably has real problems.  The interfaces definitely aren't stable.

The main features include:

* command-line testing interface
* CGI support (e.g. nginx + fcgiwrap = working service)
* Processing of query strings, and form bodies.
* A JSON structured response builder.
* URI binding and routing.
* Being able to script POSIX like a normal human, rather than calling ```system``` over and over again.

Example
-------

A basic web service:

```shell
#!/bin/bash

SCHOCKDIR=$(dirname $0)/..
. $SCHOCKDIR/kitchensink.bash

hw () {
    success 200 "Hello, World!"
}

s::route::bind::uri "/hw" "GET" hw
s::run "$@"
```


Testing a URI endpoint at the command-line:

    schock$ examples/helloworld GET /hw
    INFO: binding in route '^/hw$' 'GET' 'hw'
    DEBUG: Dumping passed in arguments:
    DEBUG: looking up handler for GET on '/hw'
    DEBUG: handler is 'hw /hw'
    DEBUG: executing handler with args '/hw'
    {
		"message": "Hello, World!"
    }
    INFO: response finished
    INFO: Header Content-Type: text/plain
    INFO: Header Status: 200


Questions & Answers
-------------------

* Isn't this a dumb idea?

    No James, it lets you prototype system services faster really quickly.

* But what about that one time I was using bash and had a quoting/globbing/whitespace/$OTHER problem?

    By default, schock turns on a more strict environment (e.g. noglob, pipefail, IFS=$'\n').  This
	Helps you help yourself.  Don't use globs for interacting with files.  Don't expect word splitting
	on space.  It can be annoying to learn to write shell scripts with those constraints, but it also
	closes the doors on some dumb mistakes.

* Will this work with ksh/pdksh/zsh/csh/tcsh/fish/...?

	Maybe, but probably not.  This code uses some bash-specifics.

* What license is this code under?

	All code in this repository is under the license defined in ```LICENSE```.  It's just a BSD 3-clause.

