all:
	gcc -std=c89 -O2 -Wall php.c -o php && ./php && rm php
