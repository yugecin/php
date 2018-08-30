# primitive css minifying

s/\s\+{/{/g
s/:\s\+/:/g
s/,\s\+/,/g
s/\t//g
s/LIGHTGREY/#a8a8a8/g
s/DARKGREY/#606060/g

H
$ {
	g
	s/\n//g
	s/}:/}\n:/g
	q
}
d

