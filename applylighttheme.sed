
/<style>$/ {
	:morestyle
	s/BLUELINK/#0000FF/g
	s/BLACK/#000/g
	s/WHITE/#fff/g
	#s/LIGHTGREY/#a8a8a8/g
	s/LIGHTGREY/#e8e8e8/g
	s/DARKGREY/#606060/g
	n
	/^<\/style>/ !{
		b morestyle
	}
}

s/\.html~INTERNALLINK~/.html/g
s/~INTERNALLINK~//g
s/\.html~INTERNALLINKINV~/_d.html/g
s/~INTERNALLINKINV~//g

s/~LIGHTSOFF~/Lights off/g

