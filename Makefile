WIKI = enwiktionary

YEAR = $(shell date +%Y)
MONTH = $(shell date +%m)

ifeq ($(shell [ $(shell date +%d) -ge 20 ]), 1)
	DAY = 20
else
	DAY = 01
endif

DUMP_DATE ?= $(YEAR)$(MONTH)$(DAY)

DUMP_PREFIX = /public/dumps/public/$(WIKI)/$(DUMP_DATE)/$(WIKI)-$(DUMP_DATE)
PAGES_META_CURRENT = $(DUMP_PREFIX)-pages-meta-current.xml.bz2
PAGES_ARTICLES = $(DUMP_PREFIX)-pages-articles.xml.bz2

SQL_DIR = $(HOME)/parse-mediawiki-sql
SQL_PREFIX = $(SQL_DIR)/$(DUMP_DATE)
TEMPLATE_REDIRECTS_DIR = $(HOME)/template_redirects
TEMPLATE_REDIRECTS_JSON = $(TEMPLATE_REDIRECTS_DIR)/$(DUMP_DATE).json

TEMPLATE_DUMP_DIR = $(HOME)/www/static/dump/$(DUMP_DATE)
TEMPLATE_NAMES = $(TEMPLATE_DUMP_DIR)/template_names.txt

template_redirects: $(TEMPLATE_REDIRECTS_JSON)

$(TEMPLATE_REDIRECTS_JSON): $(SQL_PREFIX)-page.sql $(SQL_PREFIX)-redirect.sql
	cd $(SQL_DIR) && \
		mkdir -p $(TEMPLATE_REDIRECTS_DIR) && \
		cargo run --release --example template_redirects \
		> $(TEMPLATE_REDIRECTS_JSON)

$(SQL_DIR)/$(DUMP_DATE)-%.sql:
	cd $(SQL_DIR) && \
		gunzip -c $(DUMP_PREFIX)-$*.sql.gz > $@

templates: $(TEMPLATE_REDIRECTS_JSON)
	cd $(HOME) && ./gather_template_names.py > template_names/all.txt
	cd $(HOME)/enwikt-dump-rs
	cat $(HOME)/git/template_names/all.txt | \
		$(HOME)/bin/lua lua/add_template_redirects.lua "%s.cbor" $(TEMPLATE_REDIRECTS_JSON) \
		> $(TEMPLATE_NAMES)
	mkdir -p $(TEMPLATE_DUMP_DIR) && cd $(TEMPLATE_DUMP_DIR)
	$(HOME)/bin/wiktionary-data dump-parsed-templates \
		--input $(PAGES_ARTICLES) \
		--templates $(TEMPLATE_NAMES) \
		--namespaces main,reconstruction,appendix \
		--format cbor
