#!/bin/sh

find root -name \*.xsl | while read i
do \
    j=$(echo $i | sed -e 's/root/doc/' -e 's/xsl$/md/')
    if [ \! -d `dirname $j` ]; then mkdir -p `dirname $j`; fi
    xsltproc script/doc-extract.xsl $i | pandoc -f html -t gfm > $j
done
