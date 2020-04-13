#! /usr/bin/env python3

from pywikibot import Site, Page
import re
from traceback import print_exc

site = Site(code="en", fam="wiktionary")
def gather_template_names(title):
    page = Page(site, title=title)
    return (match.group(1) for match in re.finditer(r"\{\{temp\|([^\}]+)\}\}", page.text))

try:
    template_names = set(gather_template_names("User:Erutuon/lists/templatehoard templates"))
    template_names.update(gather_template_names("Wiktionary:Templates with current language parameter"))

    template_names = list(template_names)
    template_names.sort(key=lambda name: (name.lower(), name))

    print("\n".join(template_names))
except Exception as e:
    print_exc()
