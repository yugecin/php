# some unmaintainable markup to html sed script

1 {
	s/^.*$/empty/
	h
}
1,4d

/^<pre>$/ {
	:pre
	n
	/^<\/pre>$/ !{
		b pre
	}
	n
}

s/\\}/~ENDTAG~/g

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
		s/\(.*\)\n.*$/\1\n<\/a>/
		x
		s/.*\n\(.*\){@a=\([^ ]*\) \(.*\)/\1<a href="\2">\3/
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
	s/\nempty.*\n\([^\n]\+\)\n.*}\(.*\)$/\1\2/
	x
	s/\n[^\n]*\n[^\n]*$//
	x
	s/~NEXTENDS~/}/g
	b moretags
}

s/~ENDTAG~/}/g

