
s#^\s\+\#SIMPLETAG \(.*\)$#	/{@\1\\( \\|$\\)/ {\
		H\
		g\
		s/\\(.*\\)\\n.*$/\\1\\n<\\/\1>/\
		x\
		s/.*\\n\\(.*\\){@\1 \\?\\(.*\\)/\\1<\1>\\2/\
		b nexttag\
	}\
#

