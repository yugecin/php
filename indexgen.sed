# give id's to each <h1-6> and save a list of them in the file 'INDEX'

# every h has to be on it's own line for this to work

/^<h[1-6]>.*<\/h[1-6]>$/ {
	h
	s_^<h[1-6]>\(.*\)</h[1-6]>$_\1_
	s/^\([^<]*\)<.*$/\1/
	# this should be the same as the {@#= tag process regex in tohmlt.source.sed!
	s/[^a-zA-Z0-9_.-]//g
	s/$/~END~/
	G
	h
	/<\/h1>$/ { s/^/~T~/ }
	/<\/h2>$/ { s/^/.... ~T~/ }
	/<\/h3>$/ { s/^/........ ~T~/ }
	/<\/h4>$/ { s/^/............ ~T~/ }
	/<\/h5>$/ { s/^/................ ~T~/ }
	/<\/h6>$/ { s/^/.................... ~T~/ }
	s_^\(.*\)~T~\(.*\)~END~\n<h.>\([^<]*\) \?<.*$_\1<a href="#\2">\3</a><br/>_w INDEX
	g
	s_^\(.*\)~END~\n<h\([1-6]\)>\(.*\)</h.>$_<h\2 id="\1">\3<a class="s" href="#\1">#</a></h\2>_
}

