# some unmaintainable markup to html sed script

1 {
	s/^.*$/empty/
	h
}
1,4d

:begin

/^$/ {
	d
}

/^<pre>$/ {
	N
	s/\n/<p>/
	:pre
	n
	/^<\/pre>$/ !{
		b pre
	}
	s_^_</p>_
	n
}

s/\\}/~ESCAPEDENDTAG~/g

:moretags

/^[^}]*{@/ {

	s/{@/~FIRSTTAG~/
	s/{@/~NEXTTAGS~/g
	s/~FIRSTTAG~/{@/

	/{@h1 / {
		H
		g
		s/\(.*\)\n.*$/\1\n<\/h1>/
		x
		s/.*\n\(.*\){@h1 \(.*\)/\1<h1>\2/
		b nexttag
	}

	/{@code / {
		H
		g
		s/\(.*\)\n.*$/\1\n<\/code>/
		x
		s/.*\n\(.*\){@code \(.*\)/\1<code>\2/
		b nexttag
	}

	/{@b / {
		H
		g
		s/\(.*\)\n.*$/\1\n<\/strong>/
		x
		s/.*\n\(.*\){@b \(.*\)/\1<strong>\2/
		b nexttag
	}

	/{@i / {
		H
		g
		s/\(.*\)\n.*$/\1\n<\/em>/
		x
		s/.*\n\(.*\){@i \(.*\)/\1<em>\2/
		b nexttag
	}

	/{@u / {
		H
		g
		s/\(.*\)\n.*$/\1\n<\/u>/
		x
		s/.*\n\(.*\){@u \(.*\)/\1<u>\2/
		b nexttag
	}

	/{@blockquote / {
		H
		g
		s/\(.*\)\n.*$/\1\n<\/blockquote>/
		x
		s/.*\n\(.*\){@blockquote \(.*\)/\1<blockquote>\2/
		b nexttag
	}

	/{@ia=\([^ ]*\) / {
		H
		g
		s/\(.*\)\n.*$/\1\n<\/a>/
		x
		s/.*\n\(.*\){@ia=\([^ ]*\) \(.*\)/\1<a href="\2">\3/
		b nexttag
	}

	/{@a=\([^ ]*\) / {
		H
		g
		s_\(.*\)\n.*$_\1\n</a><img src="moin-www.png" alt="external link" title="external link"/>_
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
	/@\?empty$/ {
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
	s/\n@\?empty.*\n\([^\n]\+\)\n.*}\(.*\)$/\1\2/
	x
	s/\n[^\n]*\n[^\n]*$//
	x
	s/~NEXTENDS~/}/g
	b moretags
}

s/~ESCAPEDENDTAG~/}/g

# add <p> tags
# <p> is added if line is not empty and doesn't start with <
# if <p> was added, hold space gets an @ in the beginning
# if hold space has @, next line is checked if it's empty
# if it's empty, append </p> and remove @ from hold space

# check if <p> should be prepended
/^</ !{
	x
	/^@/ {
		x
		b checkend
	}
	s/^/@/
	x
	s/^/<p>/
}

:checkend
# check if </p> should be appended
x
/^@/ {
	# peek next line to see if <p> needs to be closed
	x
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

