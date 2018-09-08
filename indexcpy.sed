# copy index from file 'INDEX' into page

/^<p>~INDEXGOESHERE~<\/p>$/ {
	i<p>
	r INDEX
	a</p>
	d
}


