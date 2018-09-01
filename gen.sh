#!/usr/bin/env bash

# $1 outputfile
# $2 inputstring (as in pages/_template.txt format)
# $3 breadcrumbs or anything that goes between nav and page content or nothing
function makepage {
	echo "$SKELETON1" > $1
	echo "$2" | head -n1 >> $1
	echo "$SKELETON23" >> $1
	echo "<header><a href=\"$1~INTERNALLINKINV~\">~LIGHTSOFF~</a></header>" >> $1
	echo "$NAV" >> $1
	if [ ! -z "$3" ]
	then
		echo "$3" >> $1
	fi
	echo "$2" | sed -f tohtml.sed >> $1
	echo "$SKELETON4" >> $1
	echo "$2" | sed -n '3p' >> $1
	echo "$SKELETON5" >> $1
	PAGEFILES+=($1)
}

PAGEFILES=()

# remove existing generated pages
ls -1 *.html | grep -v "^_" | xargs rm

# collect blog posts
mapfile -t _BLOGPOSTS < <(find blog/*.txt -maxdepth 1 -type f | grep -v "blog/_")
BLOGPOSTS=
for IX in "${_BLOGPOSTS[@]}"
do
	TS=$(head -n1 $IX)
	if [[ "$TS" = "WIP" ]]
	then
		continue
	fi
	BLOGPOSTS=$BLOGPOSTS$'\n'"$TS $IX"
done

BLOGPOSTS=$(echo "$BLOGPOSTS" | tail -n +2 | sort -n)
readarray -t BLOGPOSTS <<<"$BLOGPOSTS"

# collect pages
mapfile -t PAGES < <(find pages/*.txt -maxdepth 1 -type f | grep -v "pages/_")

# make nav
NAV=
for IX in "${PAGES[@]}"
do
	PF=${IX##*/*_}
	PN=$(head -n1 $IX)
	NAV="$NAV|<a href=\"${PF%.txt*}.html~INTERNALLINK~\">$PN</a>"
done

NAV="<nav>${NAV#*|}</nav><hr/>"

# make skeleton
SKELETON1=$(sed -f minhtml.sed _skeleton1.html)
SKELETON23=$(sed -f minhtml.sed _skeleton2.html)
SKELETON23=$SKELETON23$(sed -f mincss.sed style.css)
SKELETON23=$SKELETON23$(sed -f minhtml.sed _skeleton3.html)
SKELETON4=$(sed -f minhtml.sed _skeleton4.html)
SKELETON5=$(sed -f minhtml.sed _skeleton5.html)

# make blog posts
for IX in "${BLOGPOSTS[@]}"
do
	INPUTFILE=${IX#* }
	PF=${INPUTFILE##*/}
	PF=${PF/_/-}
	PF=blog-${PF/.txt/.html}
	echo "$PF"
	#BLOGPOSTLIST+=(${IX%% *} $PF)
	makepage "$PF" "$(tail -n +3 $INPUTFILE)"
done

echo ""

# make pages
for IX in "${PAGES[@]}"
do
	PF=${IX##*/*_}
	PF=${PF%.txt*}.html
	echo $PF
	makepage "$PF" "$(cat $IX)"
done

# light and dark theme for every page
for FROM in "${PAGEFILES[@]}"
do
	TO=${FROM%.html*}_d.html

	sed -f applydarktheme.sed < $FROM > $TO
	sed -i -f applylighttheme.sed $FROM
done

