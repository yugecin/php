# primitive css minifying

s/\s\+{/{/g
s/:\s\+/:/g
s/,\s\+/,/g
s/\t//g
s/BLACK/#000/g
s/WHITE/#fff/g
#s/LIGHTGREY/#a8a8a8/g
s/LIGHTGREY/#e8e8e8/g
s/DARKGREY/#606060/g

H
$ {
	g
	s/\n//g
	s/}:/}\n:/g
	s/;}/}/g
	q
}
d

