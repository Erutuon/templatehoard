SHELL = bash

WORK = $(HOME)/work

WIKI = enwiktionary

YEAR := $(shell date +%Y)
MONTH := $(shell date +%m)

ifeq ($(shell test $(shell date +%d) -ge 20 && echo true),true)
	DAY = 20
else
	DAY = 01
endif

START_TIME := $(shell date +%Y%m%d%H%M%S)

TEMPLATE_DUMP_TEMP_DIR        = $(WORK)/tmp/template_dumps
TEMPLATE_DUMP_TEMP            = $(TEMPLATE_DUMP_TEMP_DIR)/$(START_TIME)
TEMPLATE_NAMES_WITH_REDIRECTS = $(TEMPLATE_DUMP_TEMP)/template_names.txt

# WARNING: When DUMP_DATE is set outside the Makefile and is not the latest
# dump date, a `latest` template dump link and a `latest.json` template
# redirects link will still be created. See the lines highlighted with # !!.
DUMP_DATE ?= $(YEAR)$(MONTH)$(DAY)

DUMP_PREFIX         = /public/dumps/public/$(WIKI)/$(DUMP_DATE)/$(WIKI)-$(DUMP_DATE)
PAGES_META_CURRENT  = $(DUMP_PREFIX)-pages-meta-current.xml.bz2
PAGES_ARTICLES      = $(DUMP_PREFIX)-pages-articles.xml.bz2
SITEINFO_NAMESPACES = $(DUMP_PREFIX)-siteinfo-namespaces.json.gz

LUA = $(HOME)/bin/lua
PROCESS_WITH_LUA = $(HOME)/enwikt-dump-rs/target/release/process-with-lua

SQL_DIR      = $(HOME)/parse-mediawiki-sql
SQL_PREFIX   = $(SQL_DIR)/$(DUMP_DATE)
PAGE_SQL     = $(SQL_PREFIX)-page.sql
REDIRECT_SQL = $(SQL_PREFIX)-redirect.sql

TEMPLATE_REDIRECTS_DIR  = $(WORK)/template_redirects
TEMPLATE_REDIRECTS_JSON = $(TEMPLATE_REDIRECTS_DIR)/$(DUMP_DATE).json

TEMPLATE_DUMP_PARENT = $(HOME)/www/static/dump
TEMPLATE_DUMP_DIR    = $(TEMPLATE_DUMP_PARENT)/$(DUMP_DATE)
TEMPLATE_NAMES       = $(HOME)/git/template_names/all.txt

ENTRY_INDEX_SCRIPT   = $(HOME)/git/entry_index.lua
ENTRY_INDEX_DIR      = $(WORK)/entry_index
ENTRY_INDEX          = $(ENTRY_INDEX_DIR)/$(DUMP_DATE).txt
ENWIKTIONARY_LUA_DIR = $(HOME)/share/lua/5.3/enwiktionary
LANG_NAMES_DIR       = $(ENWIKTIONARY_LUA_DIR)/language_name_to_code
LANG_NAMES           = $(LANG_NAMES_DIR)/$(DUMP_DATE).lua

ENTRY_REDIRECTS_DIR = $(WORK)/entry_redirects
ENTRY_REDIRECTS     = $(ENTRY_REDIRECTS_DIR)/$(DUMP_DATE).txt

AUGMENTED_ENTRY_INDEX_SCRIPT = $(HOME)/git/augment_entry_index.lua
AUGMENTED_ENTRY_INDEX_DIR    = $(WORK)/augmented_entry_index
AUGMENTED_ENTRY_INDEX        = $(AUGMENTED_ENTRY_INDEX_DIR)/$(DUMP_DATE).txt

template_redirects: $(TEMPLATE_REDIRECTS_JSON)

$(TEMPLATE_REDIRECTS_JSON): $(PAGE_SQL) $(REDIRECT_SQL)
	mkdir -p $(TEMPLATE_REDIRECTS_DIR)
	cd $(SQL_DIR) && \
		cargo run --release --example template_redirects \
		$(PAGE_SQL) $(REDIRECT_SQL) \
		> $(TEMPLATE_REDIRECTS_JSON)
	ln -sfT $(TEMPLATE_REDIRECTS_JSON) $(TEMPLATE_REDIRECTS_DIR)/latest.json # !!

$(SQL_PREFIX)-%.sql:
	cd $(SQL_DIR) && \
		gunzip -c $(DUMP_PREFIX)-$*.sql.gz > $@

templates: $(TEMPLATE_REDIRECTS_JSON)
	cd $(HOME) && $(HOME)/git/gather_template_names.py > $(TEMPLATE_NAMES)
	mkdir -p $(TEMPLATE_DUMP_TEMP)
	cd $(HOME)/enwikt-dump-rs && \
		cat $(TEMPLATE_NAMES) | \
		$(LUA) lua/add_template_redirects.lua "%s.cbor" $(TEMPLATE_REDIRECTS_JSON) \
		> $(TEMPLATE_NAMES_WITH_REDIRECTS)
	cd $(TEMPLATE_DUMP_TEMP) && \
		$(HOME)/bin/wiktionary-data dump-parsed-templates \
		--input $(PAGES_ARTICLES) \
		--templates $(TEMPLATE_NAMES_WITH_REDIRECTS) \
		--namespaces main,reconstruction,appendix \
		--format cbor
	if [[ -a $(TEMPLATE_DUMP_DIR)  ]]; then mv -fT $(TEMPLATE_DUMP_DIR) $(TEMPLATE_DUMP_TEMP_DIR)/$$(date +%Y%m%d%H%M%S); fi
	mkdir -p $(TEMPLATE_DUMP_DIR)
	mv -fT $(TEMPLATE_DUMP_TEMP) $(TEMPLATE_DUMP_DIR)
	ln -sfT $(TEMPLATE_DUMP_DIR) $(TEMPLATE_DUMP_PARENT)/latest # !!
	

$(LANG_NAMES):
	mkdir -p $(LANG_NAMES_DIR)
	$(PROCESS_WITH_LUA) text \
		-i $(PAGES_META_CURRENT) \
		-n module \
		-e 'if page.title == "Module:languages/canonical names" then print(page.text) return false end return true' \
		> $(LANG_NAMES)
	
entry_index: $(ENTRY_INDEX)

$(ENTRY_INDEX): $(LANG_NAMES)
	mkdir -p $(ENTRY_INDEX_DIR)
	$(PROCESS_WITH_LUA) headers \
		-n main -n reconstruction -n appendix \
		-i $(PAGES_ARTICLES) \
		-s $(ENTRY_INDEX_SCRIPT) \
		$(LANG_NAMES) \
		> $(ENTRY_INDEX)

entry_redirects: $(ENTRY_REDIRECTS)

$(ENTRY_REDIRECTS): $(PAGE_SQL) $(REDIRECT_SQL)
	mkdir -p $(ENTRY_REDIRECTS_DIR)
	# main, appendix, reconstruction
	cd $(SQL_DIR) && \
		cargo run --release --example redirects_by_namespace -- \
		-s $(SITEINFO_NAMESPACES) -p $(PAGE_SQL) -r $(REDIRECT_SQL) 0 100 118 > $(ENTRY_REDIRECTS)

augmented_entry_index: $(AUGMENTED_ENTRY_INDEX)

$(AUGMENTED_ENTRY_INDEX): $(ENTRY_REDIRECTS) $(ENTRY_INDEX)
	mkdir -p $(AUGMENTED_ENTRY_INDEX_DIR)
	$(LUA) $(AUGMENTED_ENTRY_INDEX_SCRIPT) $(ENTRY_INDEX) $(ENTRY_REDIRECTS) \
		> $(AUGMENTED_ENTRY_INDEX)
