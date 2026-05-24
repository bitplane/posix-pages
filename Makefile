AWK ?= awk
AWKDOWN ?= ../awkdown/build/awkdown
AWKYAML ?= ../awkyaml/build/awkyaml
AWKUID ?= ../awkuid/build/awkuid
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
GITHUB_OWNER ?= bitplane
AWKDOWN_RELEASE ?= latest
AWKYAML_RELEASE ?= latest
AWKUID_RELEASE ?= latest

.PHONY: test
test: smoke jekyll

.PHONY: smoke
smoke:
	AWK="$(AWK)" AWKDOWN="$(AWKDOWN)" AWKYAML="$(AWKYAML)" AWKUID="$(AWKUID)" sh test/run-smoke.sh

.PHONY: jekyll
jekyll:
	AWK="$(AWK)" AWKDOWN="$(AWKDOWN)" AWKYAML="$(AWKYAML)" AWKUID="$(AWKUID)" sh test/jekyll/run-jekyll.sh

.PHONY: clean
clean:
	rm -rf test/tmp

.PHONY: tools
tools: tools/.stamp ## Download release tools into ./tools.

tools/.stamp: scripts/fetch-tools.sh
	GITHUB_OWNER="$(GITHUB_OWNER)" \
	AWKDOWN_RELEASE="$(AWKDOWN_RELEASE)" \
	AWKYAML_RELEASE="$(AWKYAML_RELEASE)" \
	AWKUID_RELEASE="$(AWKUID_RELEASE)" \
	sh scripts/fetch-tools.sh
	@touch $@

.PHONY: test-tools
test-tools: tools/.stamp ## Test using downloaded release tools.
	$(MAKE) test AWKDOWN=./tools/awkdown AWKYAML=./tools/awkyaml AWKUID=./tools/awkuid

.PHONY: install
install: ## Install posix-pages into BINDIR, default ~/.local/bin.
	mkdir -p "$(BINDIR)"
	cp bin/posix-pages "$(BINDIR)/posix-pages"
	chmod +x "$(BINDIR)/posix-pages"
