# some unmaintainable markup to html sed script

1 {
	s/^.*$/empty/
	h
}
1,4d

:begin

/^$/ {
	x
	s/^!//
	x
	d
}

/^<pre>$/ {
	N
	s/\n//
	:pre
	n
	/^<\/pre>$/ !{
		b pre
	}
	n
	b begin
}

s/^\s\+//
s/\s\+$//

s/\\}/~ESCAPEDENDTAG~/g

:moretags

/^[^}]*{@/ {

	s/{@/~FIRSTTAG~/
	s/{@/~NEXTTAGS~/g
	s/~FIRSTTAG~/{@/

	#SIMPLETAG h1
	#SIMPLETAG h2
	#SIMPLETAG h3
	#SIMPLETAG h4
	#SIMPLETAG h5
	#SIMPLETAG h6
	#SIMPLETAG ul
	#SIMPLETAG li
	#SIMPLETAG code
	#SIMPLETAG b
	#SIMPLETAG i
	#SIMPLETAG u
	#SIMPLETAG blockquote

	/{@small / {
		H
		g
		s/\(.*\)\n.*$/\1\n<\/span>/
		x
		s/.*\n\(.*\){@small \(.*\)/\1<span class="small">\2/
		b nexttag
	}

	/{@ia=\([^ ]*\) / {
		H
		g
		s/\(.*\)\n.*$/\1\n<\/a>/
		x
		s/.*\n\(.*\){@ia=\([^ ]*\) \(.*\)/\1<a href="\2~INTERNALLINK~">\3/
		b nexttag
	}

	/{@a=\([^ ]*\) / {
		H
		g
		s_\(.*\)\n.*$_\1\n</a><img src="moin-www.png" alt="globe icon" title="external link"/>_
		x
		s/.*\n\(.*\){@a=\([^ ]*\) \(.*\)/\1<a href="\2">\3/
		b nexttag
	}

	/{@hr}/ {
		s_{@hr}_<hr/>_
		b nexttag
	}

	a<h1>unknown tag</h1>
	q

	:nexttag
	s/~NEXTTAGS~/{@/g
	b moretags
}

/}/ {
	x
	/empty$/ {
		x
		a<h1>tag stack is empty!</h1>
		q
	}
	x
	s/}/~FIRSTEND~/
	s/}/~NEXTENDS~/g
	s/~FIRSTEND~/}/
	H
	s/^\([^}]*\)}.*$/\1/
	G
	s/\n[@!]\?empty.*\n\([^\n]\+\)\n.*}\(.*\)$/\1\2/
	x
	s/\n[^\n]*\n[^\n]*$//
	x
	s/~NEXTENDS~/}/g
	b moretags
}

s/~ESCAPEDENDTAG~/}/g

# add <p> tags
# opening tag should be added on lines that either don't start
# with a '<' or start with tags that are allowed inside para's
# (such as '<a>' or '<span>')

# if this condition doesn't match, hold space gets a ! in the
# beginning. this ! means a paragraph can't be inserted.
# the ! is removed again when an empty line is found (this
# happens in the top section of the script where empty lines
# are ditched)

# if the condition does match, hold space gets a @ in the front
# and the opening <p> tag is inserted (unless hold space already
# had a @ symbol)

# adding the closing tag is done by checking if the next line
# is empty and if hold space has a @ symbol, meaning one is
# currently opened and should be closed. if that's the case,
# append a </p> and remove the @ from hold space

# check if <p> can be prepended
/^\(<a\|<span\|[^<]\)/ {
	x
	/^!/ {
		x
		n
		b begin
	}
	/^@/ {
		x
		b checkend
	}
	s/^/@/
	x
	s/^/<p>/
	b checkend
}

# cannot be prepended so mark state as such
# (only if not already prepended)
# this will be reset when an empty line is found (see top)
x
/^@/ !{
	/^!/ !{
		s/^/!/
	}
	x
	n
	b begin
}
x

:checkend
# check if </p> should be appended
x
/^@/ {
	# peek next line to see if <p> needs to be closed
	x
	$ {
		# eof, yes (last non-empty line is eof apparently)
		s_$_</p>_
		q
	}
	N
	/\n$/ !{
		# no, print previous pattern space and
		# continue with next
		s/^/~BEGIN~/
		H
		s/^~BEGIN~\(.*\)\n.*$/\1/p
		g
		s/~BEGIN~.*$//
		x
		s/^.*\n//
		b begin
	}

	# yes
	s_\n_</p>_
	x
	s/^@//
}
x

