# primitive html minifying
# basically only removes tabs and linebreaks

s/\t//g

H
$ {
	g
	s/\n//g
	q
}
d

