# primitive css minifying

s/\s\+{/{/g
s/:\s\+/:/g
s/,\s\+/,/g
s/\t//g

H
$ {
	g
	s/\n//g
	q
}
d

