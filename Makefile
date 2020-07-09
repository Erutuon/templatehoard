WIKI = enwiktionary

YEAR = $(shell date +%Y)
MONTH = $(shell date +%m)

ifeq ($(shell test $(shell date +%d) -ge 20 && echo true),true)
	DAY = 20
else
	DAY = 01
endif

START_TIME = $(shell date +%Y%m%d%H%M)

DUMP_DATE ?= $(YEAR)$(MONTH)$(DAY)
DUMP_PREFIX = /public/dumps/public/$(WIKI)/$(DUMP_DATE)/$(WIKI)-$(DUMP_DATE)
PAGES_META_CURRENT = $(DUMP_PREFIX)-pages-meta-current.xml.bz2
PAGES_ARTICLES = $(DUMP_PREFIX)-pages-articles.xml.bz2

LUA = $(HOME)/bin/lua
PROCESS_WITH_LUA = $(HOME)/enwikt-dump-rs/target/release/process-with-lua

SQL_DIR = $(HOME)/parse-mediawiki-sql
SQL_PREFIX = $(SQL_DIR)/$(DUMP_DATE)
PAGE_SQL     = $(SQL_PREFIX)-page.sql
REDIRECT_SQL = $(SQL_PREFIX)-redirect.sql

TEMPLATE_REDIRECTS_DIR = $(HOME)/template_redirects
TEMPLATE_REDIRECTS_JSON = $(TEMPLATE_REDIRECTS_DIR)/$(DUMP_DATE).json

TEMPLATE_DUMP_DIR = $(HOME)/www/static/dump/$(DUMP_DATE)
TEMPLATE_NAMES = $(HOME)/git/template_names/all.txt
TEMPLATE_NAMES_WITH_REDIRECTS = $(TEMPLATE_DUMP_DIR)/template_names.txt

ENTRY_INDEX_SCRIPT = $(HOME)/git/entry_index.lua
ENTRY_INDEX_DIR = $(HOME)/entry_index
ENTRY_INDEX = $(ENTRY_INDEX_DIR)/$(DUMP_DATE).txt
ENWIKTIONARY_LUA_DIR = $(HOME)/share/lua/5.3/enwiktionary

ENTRY_REDIRECTS_DIR = $(HOME)/entry_redirects
ENTRY_REDIRECTS = $(ENTRY_REDIRECTS_DIR)/$(DUMP_DATE).txt

AUGMENTED_ENTRY_INDEX_SCRIPT = $(HOME)/git/augment_entry_index.lua
AUGMENTED_ENTRY_INDEX_DIR = $(HOME)/augmented_entry_index
AUGMENTED_ENTRY_INDEX = $(AUGMENTED_ENTRY_INDEX_DIR)/$(DUMP_DATE).txt

template_redirects: $(TEMPLATE_REDIRECTS_JSON)

$(TEMPLATE_REDIRECTS_JSON): $(PAGE_SQL) $(REDIRECT_SQL)
	mkdir -p $(TEMPLATE_REDIRECTS_DIR)
	cd $(SQL_DIR) && \
		cargo run --release --example template_redirects \
		$(PAGE_SQL) $(REDIRECT_SQL) \
		> $(TEMPLATE_REDIRECTS_JSON)

$(SQL_PREFIX)-%.sql:
	cd $(SQL_DIR) && \
		gunzip -c $(DUMP_PREFIX)-$*.sql.gz > $@

templates: $(TEMPLATE_REDIRECTS_JSON)
	cd $(HOME) && $(HOME)/git/gather_template_names.py > $(TEMPLATE_NAMES)
	cd $(HOME)/enwikt-dump-rs && \
		cat $(TEMPLATE_NAMES) | \
		$(LUA) lua/add_template_redirects.lua "%s.cbor" $(TEMPLATE_REDIRECTS_JSON) \
		> $(TEMPLATE_NAMES_WITH_REDIRECTS)
	mkdir -p $(HOME)/tmp/template_dumps/$(START_TIME) && \
		cd $(HOME)/tmp/template_dumps/$(START_TIME) && \
		$(HOME)/bin/wiktionary-data dump-parsed-templates \
		--input $(PAGES_ARTICLES) \
		--templates $(TEMPLATE_NAMES_WITH_REDIRECTS) \
		--namespaces main,reconstruction,appendix \
		--format cbor
	mv -fT $(TEMPLATE_DUMP_DIR) ../$$(date +%Y%m%d%H%M) && mkdir -p $(TEMPLATE_DUMP_DIR) \
		&& mv -fT $(START_TIME) $(TEMPLATE-DUMP_DIR)
	

$(ENWIKTIONARY_LUA_DIR)/language_name_to_code.lua:
	$(PROCESS_WITH_LUA) text \
		-i $(PAGES_META_CURRENT) \
		-n module \
		-e 'if page.title == "Module:languages/canonical names" then print(page.text) return false end return true' \
		> $(ENWIKTIONARY_LUA_DIR)/language_name_to_code.lua
	
entry_index: $(ENTRY_INDEX)

$(ENTRY_INDEX): $(ENWIKTIONARY_LUA_DIR)/language_name_to_code.lua
	mkdir -p $(ENTRY_INDEX_DIR)
	$(PROCESS_WITH_LUA) headers \
		-n main -n reconstruction -n appendix \
		-i $(PAGES_ARTICLES) \
		-s $(ENTRY_INDEX_SCRIPT) \
		> $(ENTRY_INDEX)

entry_redirects: $(ENTRY_REDIRECTS)

$(ENTRY_REDIRECTS):
	mkdir -p $(ENTRY_REDIRECTS_DIR)
	# main, appendix, reconstruction
	cd $(SQL_DIR) && \
		cargo run --release --example redirects_by_namespace 0 100 118 > $(ENTRY_REDIRECTS)

augmented_entry_index: $(AUGMENTED_ENTRY_INDEX)

$(AUGMENTED_ENTRY_INDEX): $(ENTRY_REDIRECTS) $(ENTRY_INDEX)
	mkdir -p $(AUGMENTED_ENTRY_INDEX_DIR)
	$(LUA) $(AUGMENTED_ENTRY_INDEX_SCRIPT) $(ENTRY_INDEX) $(ENTRY_REDIRECTS) \
		> $(AUGMENTED_ENTRY_INDEX)
