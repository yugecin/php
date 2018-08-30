#!/usr/bin/env bash

MINCSS=minstyle.css
sed -f mincss.sed style.css > MINCSS

ls -1 *.html | grep -v "^_" | xargs rm

mapfile -t PAGES < <(find pages/ -maxdepth 1 -type f)

for IX in "${PAGES[@]}"
do
	PN=${IX##*/}

	if [[ "${PN:0:1}" = "_" ]]
	then
		continue
	fi

	echo $PN

	sed -f minhtml.sed _skeleton1.html > $PN
	head -n1 $IX >> $PN
	sed -f minhtml.sed _skeleton2.html >> $PN
	cat MINCSS >> $PN
	sed -f minhtml.sed _skeleton3.html >> $PN
	sed -n '5,$p' <$IX >> $PN
	sed -f minhtml.sed _skeleton4.html >> $PN
	sed -n '3p' <$IX >> $PN
	sed -f minhtml.sed _skeleton5.html >> $PN
done

rm MINCSS
