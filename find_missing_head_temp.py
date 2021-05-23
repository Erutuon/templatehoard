#! /usr/bin/env python3

import re

# from https://en.wiktionary.org/wiki/Special:AbuseFilter/68
with open("pos_list.txt", mode = "r") as f:
    pos_list = f.read().splitlines()

pos_re = "|".join(pos.replace(" ", r"\s*").lower() + r"(?:\s*\d+)?" for pos in pos_list)
no_head_re = r"""(?isx)
    (===+) \s* (?P<header> {pos_re} ) \s* \1
    \n+ (?!{{)
    (?P<content>
        # line that is not a headword-line template or a definition
        (?: (?!\#) [^\n]+ \n+ )?
            \# [^\n]*          # definition 1
            ( \n+ \# [^\n]* )* # more definitions
        | [^\n]*               # any line
    )
""".format(pos_re = pos_re)


def escape_tsv(s: str):
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")


def iter_missing_head_temps(text: str):
    for match in re.finditer(
        r"(?s)==\s*(?P<language>[^=\n]+)\s*==\n+(?P<entry>.+?)(?=$|\n+==[^=])", text
    ):
        language, entry = match.group("language"), match.group("entry")
        for match in re.finditer(
            no_head_re,
            entry,
        ):
            yield language, match.group(0)


if __name__ == "__main__":
    from pywikibot import Site, Page

    def print_missing_head_temps(text: str):
        for language, missing_head_temp in iter_missing_head_temps(text):
            print(
                "language = " + language + "\nmissing_head_temp = " + escape_tsv(missing_head_temp)
            )

    enwiktionary = Site(code="en", fam="wiktionary")

    print_missing_head_temps(Page(enwiktionary, title="осе").text)

    print_missing_head_temps(
        """
==English==

===Noun===
'''test'''

#hmmm

#yes
"""
    )
