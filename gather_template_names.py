#! /usr/bin/env python3

from pywikibot import Site, Page
import re

site = Site(code="en", fam="wiktionary")
title = "Wiktionary:Templates with current language parameter"
page = Page(site, title=title)

template_names = [ match.group(1) for match in re.finditer(r"\{\{temp\|([^\}]+)\}\}", page.text) ]
template_names.sort(key=lambda name: (name.lower(), name))
print("\n".join(template_names))

