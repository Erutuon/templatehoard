WIKI=enwiktionary

YEAR=$(date +%Y)
MONTH=$(date +%m)
if [ $(date +%d) -ge 20 ]; then
    DAY=20;
else
    DAY=01;
fi
DUMP_DATE=$YEAR$MONTH$DAY

DUMP_PREFIX=/public/dumps/public/$WIKI/$DATE/$WIKI-$DATE
PAGES_META_CURRENT=$DUMP_PREFIX-pages-meta-current.xml.bz2
PAGES_ARTICLES=$DUMP_PREFIX-pages-articles.xml.bz2
