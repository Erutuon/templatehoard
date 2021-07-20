#! /usr/bin/env python3

from sys import argv, exit
from traceback import print_exc
import re
from datetime import datetime
from pywikibot import Site, Page
import toolforge
from pymysql.cursors import DictCursor

output_title = "User:Erutuon/lists/non-mainspace long pages"

if len(argv) < 2:
    exit("Provide edit summary in first argument")

summary = argv[1]

enwiktionary = Site(code = "en", fam = "wiktionary")
output_page = Page(enwiktionary, title = output_title)

queries = [
"""
-- Generated from siteinfo-namespaces in the dump;
-- namespaces.name is the local name, not the canonical name.
with namespace(id, name) as (
values
    (-2, 'Media'),
    (-1, 'Special'),
    (0, ''),
    (1, 'Talk'),
    (2, 'User'),
    (3, 'User talk'),
    (4, 'Wiktionary'),
    (5, 'Wiktionary talk'),
    (6, 'File'),
    (7, 'File talk'),
    (8, 'MediaWiki'),
    (9, 'MediaWiki talk'),
    (10, 'Template'),
    (11, 'Template talk'),
    (12, 'Help'),
    (13, 'Help talk'),
    (14, 'Category'),
    (15, 'Category talk'),
    (90, 'Thread'),
    (91, 'Thread talk'),
    (92, 'Summary'),
    (93, 'Summary talk'),
    (100, 'Appendix'),
    (101, 'Appendix talk'),
    (102, 'Concordance'),
    (103, 'Concordance talk'),
    (104, 'Index'),
    (105, 'Index talk'),
    (106, 'Rhymes'),
    (107, 'Rhymes talk'),
    (108, 'Transwiki'),
    (109, 'Transwiki talk'),
    (110, 'Thesaurus'),
    (111, 'Thesaurus talk'),
    (114, 'Citations'),
    (115, 'Citations talk'),
    (116, 'Sign gloss'),
    (117, 'Sign gloss talk'),
    (118, 'Reconstruction'),
    (119, 'Reconstruction talk'),
    (828, 'Module'),
    (829, 'Module talk'),
    (2300, 'Gadget'),
    (2301, 'Gadget talk'),
    (2302, 'Gadget definition'),
    (2303, 'Gadget definition talk')
)
select
    replace(concat(
        if(namespace.name = '', '', concat(namespace.name, ':')),
        page_title
    ), '_', ' ') as title,
    page_len as bytes,
    page_namespace,
    page_title
from page
left join namespace on namespace.id = page_namespace
where page_namespace <> 0
order by page_len desc
limit 5000;
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
        
        for row in rows:
            table_row = '|-\n| [[{title}]] || {bytes} || data-sort-value="{page_namespace:03}{page_title}" title="{page_namespace}, {page_title}" |'.format(
                title = row["title"].decode("utf8"),
                bytes = int(row["bytes"]),
                page_namespace = int(row["page_namespace"]),
                page_title = row["page_title"].decode("utf8")
            )
            printed.append(table_row)
        
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
                start + maybe_newline + text + maybe_newline + end,
                s,
                flags = re.S
            )
        
        output_page.text = (
            insert_in_delimiters(
                insert_in_delimiters(
                    output_page.text,
                    "rows",
                    edit_list,
                    with_newlines = True
                ),
                "date",
                "{:%Y-%m-%d %H:%M:%S}".format(query_start)
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
