WIKI=enwiktionary

YEAR=$(date +%Y)
MONTH=$(date +%m)
if [ $(date +%d) -ge 20 ]; then
    DAY=20;
else
    DAY=01;
fi
export DUMP_DATE=$YEAR$MONTH$DAY

export DUMP_PREFIX=/public/dumps/public/$WIKI/$DUMP_DATE/$WIKI-$DUMP_DATE
export PAGES_META_CURRENT=$DUMP_PREFIX-pages-meta-current.xml.bz2
export PAGES_ARTICLES=$DUMP_PREFIX-pages-articles.xml.bz2
