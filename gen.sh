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
sed -f tohtml.gen.sed < tohtml.source.sed > tohtml.sed

# remove existing generated pages
ls -1 *.html | grep -v "^_" | xargs rm

echo "collecting blog"

# make blog page (continues below)
BLOGPAGE=pages/02_blog.txt
cat pages/_02_blog_template.txt > $BLOGPAGE
echo "<ul>" >> $BLOGPAGE

# collect blog posts
mapfile -t _BLOGPOSTS < <(find blog/*.txt -maxdepth 1 -type f | grep -v "blog/_")
BLOGPOSTS=
for IX in "${_BLOGPOSTS[@]}"
do
	TIMESTAMP=$(head -n1 $IX)
	if [[ "$TIMESTAMP" = "WIP" ]]
	then
		continue
	fi
	OUTPUTFILE=${IX##*/}
	OUTPUTFILE=${OUTPUTFILE/_/-}
	OUTPUTFILE=blog-${OUTPUTFILE/.txt/.html}
	TITLE=$(head -n 3 $IX | tail -n 1)
	DATE=$(date -d @$TIMESTAMP +"%0d %b %Y")
	BLOGPOSTS=$BLOGPOSTS$'\n'"$DATE|$IX $OUTPUTFILE $TITLE"
	echo "{@li $DATE - {@ia=$OUTPUTFILE $TITLE}}" >> $BLOGPAGE
done

echo "</ul>" >> $BLOGPAGE
echo "" >> $BLOGPAGE

BLOGPOSTS=$(echo "$BLOGPOSTS" | tail -n +2 | sort -n)
readarray -t BLOGPOSTS <<<"$BLOGPOSTS"

# collect pages
mapfile -t PAGES < <(find pages/*.txt -maxdepth 1 -type f | grep -v "pages/_")

echo "make nav and pre skeleton"

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
BLOGTOP=$(sed -f tohtml.sed < blog/_top_template.txt)

# make blog posts
echo ""
for IX in "${BLOGPOSTS[@]}"
do
	DATE=${IX%%|*}
	INPUTFILE=${IX#*|}
	OUTPUTFILE=${INPUTFILE#* }
	TITLE=${OUTPUTFILE#* }
	INPUTFILE=${INPUTFILE%% *}
	OUTPUTFILE=${OUTPUTFILE%% *}
	echo "$INPUTFILE"
	TOP=${BLOGTOP//~TITLE~/"$TITLE"}
	TOP=${TOP//~INPUTFILE~/"$INPUTFILE"}
	TOP=${TOP//~OUTPUTFILE~/"$OUTPUTFILE"}
	TOP=${TOP//~PUBDATE~/"$DATE"}
	makepage "$OUTPUTFILE" "$(tail -n +3 $INPUTFILE)" "$TOP"
	sed -i "$OUTPUTFILE" -f indexgen.sed
	sed -i "$OUTPUTFILE" -f indexcpy.sed
	rm INDEX
done

# make pages
echo ""
for IX in "${PAGES[@]}"
do
	PF=${IX##*/*_}
	PF=${PF%.txt*}.html
	echo $PF
	makepage "$PF" "$(cat $IX)"
done

makepage "404.html" "$(cat pages/_404.txt)"

# light and dark theme for every page
echo ""
echo "turning lights on and off"
for FROM in "${PAGEFILES[@]}"
do
	TO=${FROM%.html*}_d.html

	sed -f applydarktheme.sed < $FROM > $TO
	sed -i -f applylighttheme.sed $FROM
done

