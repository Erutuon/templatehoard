#! /usr/bin/env python3

from sys import argv, exit
from traceback import print_exc
import re
from datetime import datetime
from pywikibot import Site, Page
from pywikibot.pagegenerators import PreloadingGenerator
import toolforge
from pymysql.cursors import DictCursor

from find_missing_head_temp import iter_missing_head_temps, escape_tsv

output_title = "Wiktionary:missing headword-line templates"

if len(argv) < 2:
    exit("Provide edit summary in first argument")

summary = argv[1]

enwiktionary = Site(code = "en", fam = "wiktionary")
output_page = Page(enwiktionary, title = output_title)

queries = [
    "set @no_head_temp = (select ctd_id from change_tag_def where ctd_name = 'no head temp')",
    "set @mw_rollback = (select ctd_id from change_tag_def where ctd_name = 'mw-rollback')",
"""
select
    replace(page_title, '_', ' ') as title,
    actor_name as editor,
    date_format(rev_timestamp, '%Y-%m-%d %T') as datetime,
    rev_id as revision,
    if(rev_id = page_latest, 'latest', '') as latest
from revision
join change_tag on ct_rev_id = rev_id
join actor      on actor_id  = rev_actor
join page       on page_id   = rev_page
where ct_tag_id = @no_head_temp
and page_namespace = 0
and rev_timestamp >= '2018'
-- previous revision doesn't have "no head temp" tag or the "mw-rollback" tag
and not exists(
    select 1 from change_tag parent_revision
    where parent_revision.ct_rev_id = rev_parent_id
    and parent_revision.ct_tag_id in (@no_head_temp, @mw_rollback)
)
-- current revision has "no head temp" tag
and exists(
    select 1 from change_tag current_revision
    where current_revision.ct_rev_id = page_latest
    and current_revision.ct_tag_id = @no_head_temp
)
order by page_title asc, `datetime` desc
"""
]

try:
    conn = toolforge.connect("enwiktionary")

    query_start = datetime.today()
    printed = []
    with conn.cursor(DictCursor) as cur:
        for query in queries:
            cur.execute(query = query)
        rows = cur.fetchall()
        # rows = cur.fetchmany(20)
        print("query yielded {} rows".format(len(rows)))
        titles = [row["title"].decode() for row in rows]
        pages = {
            page.title(): page
            for page in PreloadingGenerator(
                (Page(enwiktionary, title = title) for title in titles),
                groupsize = 5000
            )
        }
        for row in rows:
            title = row["title"].decode()
            tsv_row = "{title}\t{editor}\t{datetime}\t{revision}\t{latest}".format(
                revision = row["revision"],
                title = title,
                datetime = row["datetime"],
                editor = row["editor"].decode(),
                latest = row["latest"]
            )
            row_page = pages.get(title)
            if row_page is not None:
                for language, text in iter_missing_head_temps(row_page.text):
                    text = escape_tsv(text)
                    tsv_row += "\t{language}\t<nowiki>{text}</nowiki>".format(
                        language = language, text = text
                    )
            printed.append(tsv_row)
        edit_list = "\n".join(printed)
        
        def insert_in_delimiters(s, name, text, with_newlines = False):
            def comment(contents):
                return "<!-- " + contents + " -->"
            
            def regexify(comment):
                return re.escape(comment).replace(r"\ ", r"\s*")
            
            start = comment("start " + name)
            end = comment("end " + name)
            regex = regexify(start) + ".+?" + regexify(end)
            maybe_newline = "\n" if with_newlines else ""
            return re.sub(
                regex,
                start + maybe_newline + text.replace("\\", "\\\\") + maybe_newline + end,
                s,
                flags = re.S
            )
        
        output_page.text = (
            insert_in_delimiters(
                insert_in_delimiters(
                    output_page.text,
                    "list",
                    edit_list,
                    with_newlines = True
                ),
                "date",
                "{:%Y-%m-%d %H:%M}".format(query_start)
            )
        )
        
        # print(output_page.text)
        
        output_page.save(summary = summary, minor = False)
        
except Exception as e:
    print_exc()
finally:
    try:
        cur.close()
    except Exception as e:
        pass
    conn.close()
