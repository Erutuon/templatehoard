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
    replace(page_title, '_', ' ')                                                    as title,
    actor_name                                                                       as editor,
    date_format(first_no_head_temp.rev_timestamp, '%Y-%m-%d %T')                     as datetime,
    first_no_head_temp.rev_id                                                        as revision,
    if(first_no_head_temp.rev_id = first_no_head_temp_page.page_latest, 'yes', 'no') as latest,
    -- parent_revision.rev_id                                                           as parent_revision,
    date_format(parent_revision.rev_timestamp, '%Y-%m-%d %T')                        as parent_datetime
from revision first_no_head_temp
join      change_tag first_no_head_temp_tag  on first_no_head_temp_tag.ct_rev_id = first_no_head_temp.rev_id
join      actor                              on actor_id                         = first_no_head_temp.rev_actor
join      page       first_no_head_temp_page on page_id                          = first_no_head_temp.rev_page

left join revision   parent_revision         on parent_revision.rev_id           = first_no_head_temp.rev_parent_id

where first_no_head_temp_tag.ct_tag_id       = @no_head_temp
and   first_no_head_temp_page.page_namespace = 0
-- and   first_no_head_temp.rev_timestamp       >= '2017'
-- previous revision doesn't have "no head temp" tag or the "mw-rollback" tag
and not exists(
    select 1 from change_tag parent_revision_tag
    where parent_revision_tag.ct_rev_id =  first_no_head_temp.rev_parent_id
    and   parent_revision_tag.ct_tag_id in (@no_head_temp, @mw_rollback)
)
-- current revision has "no head temp" tag
and exists(
    select 1 from change_tag current_revision
    where current_revision.ct_rev_id = first_no_head_temp_page.page_latest
    and   current_revision.ct_tag_id = @no_head_temp
)
order by page_title asc, `datetime` desc;
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
        
        # The query returns multiple rows for some pages.
        # This dict allows displaying only the first one (that is, the one with the latest revision).
        already_seen = dict()
        
        for row in rows:
            title = row["title"].decode()
            if title not in already_seen:
                already_seen[title] = True
            else:
                continue
            
            parent_datetime = row["parent_datetime"]
            # the parent revision was submitted after the abuse filter that adds the `no head temp` tag was created
            # as revisions before that time will not have the tag unless someone added it manually,
            show_revision = parent_datetime is None or parent_datetime > "2017-05-22 15:53"
            
            tsv_row = "{title}\t{editor}\t{datetime}\t{revision}\t{latest}".format(
                revision = row["revision"] if show_revision else "",
                title = title,
                datetime = row["datetime"] if show_revision else "",
                editor = row["editor"].decode() if show_revision else "",
                latest = row["latest"] if show_revision else ""
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
