
/<style>/ {
	:morestyle
	s/BLUELINK/#9090FF/g
	s/BLACK/#fff/g
	s/WHITE/#000/g
	#s/LIGHTGREY/#a8a8a8/g
	s/LIGHTGREY/#171717/g
	s/DARKGREY/#9f9f9f/g
	n
	/^<header>/ !{
		b morestyle
	}
}

s/\.html~INTERNALLINK~/_d.html/g
s/~INTERNALLINK~//g
s/_d\.html~INTERNALLINKINV~/.html/g
s/~INTERNALLINKINV~//g

s/~LIGHTSOFF~/Lights on/g

