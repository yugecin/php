#!/usr/bin/env bash

ls -1 *.html | grep -v "^_" | xargs rm

mapfile -t PAGES < <(find pages/*.txt -maxdepth 1 -type f | grep -v "pages/_")

NAV=
for IX in "${PAGES[@]}"
do
	PF=${IX##*/*_}
	PN=$(head -n1 $IX)
	NAV="$NAV|<a href=\"${PF%.txt*}.html~INTERNALLINK~\">$PN</a>"
done

NAV="<nav>${NAV#*|}</nav><hr/>"

SKELETON1=$(sed -f minhtml.sed _skeleton1.html)
SKELETON23=$(sed -f minhtml.sed _skeleton2.html)
SKELETON23=$SKELETON23$(sed -f mincss.sed style.css)
SKELETON23=$SKELETON23$(sed -f minhtml.sed _skeleton3.html)
SKELETON4=$(sed -f minhtml.sed _skeleton4.html)
SKELETON5=$(sed -f minhtml.sed _skeleton5.html)

PAGEFILES=()

for IX in "${PAGES[@]}"
do
	PF=${IX##*/*_}
	PF=${PF%.txt*}.html
	PAGEFILES+=($PF)

	echo $PF

	echo $SKELETON1 > $PF
	head -n1 $IX >> $PF
	echo $SKELETON23 >> $PF
	echo "<header><a href=\"$PF~INTERNALLINKINV~\">~LIGHTSOFF~</a></header>" >> $PF
	echo $NAV >> $PF
	sed -f tohtml.sed <$IX >> $PF
	echo $SKELETON4 >> $PF
	sed -n '3p' <$IX >> $PF
	echo $SKELETON5 >> $PF
done

for FROM in "${PAGEFILES[@]}"
do
	TO=${FROM%.html*}_d.html

	sed -f applydarktheme.sed < $FROM > $TO
	sed -i -f applylighttheme.sed $FROM
done

