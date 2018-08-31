#!/usr/bin/env bash

MINCSS=minstyle.css
sed -f mincss.sed style.css > $MINCSS

ls -1 *.html | grep -v "^_" | xargs rm

mapfile -t PAGES < <(find pages/ -maxdepth 1 -type f | grep -v "pages/_")

NAV=
for IX in "${PAGES[@]}"
do
	PF=${IX##*/*_}
	PN=$(head -n1 $IX)
	NAV="$NAV|<a href=\"$PF\">$PN</a>"
done

NAV="<header>${NAV#*|}</header><hr/>"

for IX in "${PAGES[@]}"
do
	PF=${IX##*/*_}

	echo $PF

	sed -f minhtml.sed _skeleton1.html > $PF
	head -n1 $IX >> $PF
	sed -f minhtml.sed _skeleton2.html >> $PF
	cat $MINCSS >> $PF
	sed -f minhtml.sed _skeleton3.html >> $PF
	echo $NAV >> $PF
	sed -f tohtml.sed <$IX >> $PF
	sed -f minhtml.sed _skeleton4.html >> $PF
	sed -n '3p' <$IX >> $PF
	sed -f minhtml.sed _skeleton5.html >> $PF
done

rm $MINCSS
