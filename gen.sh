#!/usr/bin/env bash

MINCSS=$(sed -f mincss.sed style.css)

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

PAGEFILES=()

for IX in "${PAGES[@]}"
do
	PF=${IX##*/*_}
	PF=${PF%.txt*}.html
	PAGEFILES+=($PF)

	echo $PF

	sed -f minhtml.sed _skeleton1.html > $PF
	head -n1 $IX >> $PF
	sed -f minhtml.sed _skeleton2.html >> $PF
	echo $MINCSS >> $PF
	sed -f minhtml.sed _skeleton3.html >> $PF
	echo "<header><a href=\"$PF~INTERNALLINKINV~\">~LIGHTSOFF~</a></header>" >> $PF
	echo $NAV >> $PF
	sed -f tohtml.sed <$IX >> $PF
	sed -f minhtml.sed _skeleton4.html >> $PF
	sed -n '3p' <$IX >> $PF
	sed -f minhtml.sed _skeleton5.html >> $PF
done

for FROM in "${PAGEFILES[@]}"
do
	TO=${FROM%.html*}_d.html

	cat $FROM > $TO

	sed -i -f applylighttheme.sed $FROM
	sed -i -f applydarktheme.sed $TO
done

